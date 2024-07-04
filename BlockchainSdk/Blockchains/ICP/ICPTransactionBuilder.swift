//
//  ICPTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import CryptoKit
import PotentCBOR
import Combine
import TangemSdk

final class ICPTransactionBuilder {
    /// Only TrustWallet signer input transfer key (not for use public implementation)
    private var inputPrivateKey = try! Secp256k1Utils().generateKeyPair()
    
    // MARK: - Private Properties
    
    private let wallet: Wallet
    
    // MARK: - Init
    
    init(wallet: Wallet) {
        self.wallet = wallet
    }
    
    // MARK: - Implementation
    
    public func buildForSignOld(
        transaction: Transaction
    ) throws -> Data {
        let input = input(transaction: transaction)
        let txInputData = try input.serializedData()
        
        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }
        
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: .internetComputer, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)
        
        guard preSigningOutput.error == .ok, !preSigningOutput.data.isEmpty else {
            Log.debug("AptosPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.data
    }
    
    private func input(transaction: Transaction) -> InternetComputerSigningInput {
        InternetComputerSigningInput.with {
            $0.transaction = InternetComputerTransaction.with {
                $0.transfer = InternetComputerTransaction.Transfer.with {
                    $0.toAccountIdentifier = transaction.destinationAddress
                    $0.amount = (transaction.amount.value * wallet.blockchain.decimalValue).uint64Value
                    $0.memo = 0
                    $0.currentTimestampNanos = UInt64(Date().timeIntervalSince1970)
                }
            }
        }
    }
    
    func buildForSendOld(transaction: Transaction, signature: Data) throws -> String {
        let input = input(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let compiledTransaction = TransactionCompiler.compileWithSignatures(
            coinType: .internetComputer,
            txInputData: txInputData,
            signatures: signature.asDataVector(),
            publicKeys: wallet.publicKey.blockchainKey.asDataVector()
        )
        
        let signingOutput = try InternetComputerSigningOutput(serializedData: compiledTransaction)

        guard signingOutput.error == .ok, !signingOutput.signedTransaction.isEmpty else {
            Log.debug("AptosSigningOutput has a error")
            throw WalletError.failedToBuildTx
        }
        
        return signingOutput.signedTransaction.hexString
    }
    
    /// Build input for sign transaction from Parameters
    /// - Parameters:
    ///   - transaction: Transaction
    /// - Returns: ICPSigningInput for sign transaction with external signer
    public func buildForSign(
        transaction: Transaction
    ) throws -> ICPSigningInput {
        ICPSigningInput(
            source: transaction.sourceAddress,
            destination: transaction.destinationAddress,
            amount: transaction.amount.value * wallet.blockchain.decimalValue,
            memo: nil
        )
    }
    
    /// Build for send transaction obtain external message output
    /// - Parameters:
    ///   - input: TW output of message
    /// - Returns: InternetComputerSigningOutput for ICP blockchain
    public func buildForSend(output: ICPRequestEnvelope) throws -> Data {
        try ICPCryptography.CBOR.serialise(output)
    }
}

struct ICPSigningInput {
    let source: String
    let destination: String
    let amount: Decimal
    let memo: UInt64?
    
    init(transaction: Transaction) {
        source = transaction.sourceAddress
        destination = transaction.destinationAddress
        amount = transaction.amount.value
        memo = nil
    }
    
    init(source: String, destination: String, amount: Decimal, memo: UInt64?) {
        self.source = source
        self.destination = destination
        self.amount = amount
        self.memo = memo
    }
}

struct ICPSinger {
    let signer: TransactionSigner
    let walletPublicKey: Wallet.PublicKey
    
    init(signer: TransactionSigner, walletPublicKey: Wallet.PublicKey) {
        self.signer = signer
        self.walletPublicKey = walletPublicKey
    }
    
    static let defaultIngressExpirySeconds: TimeInterval = 4 * 60 // 4 minutes
    
    func sign(input: ICPSigningInput) -> AnyPublisher<ICPSigningOutput, Error> {
        do {
            let data = try requestsData(input: input)
            let domain = ICPDomainSeparator("ic-request")
            
            let contents = [data.callRequestContent, data.readStateRequestContent]
            let hashes = try contents.map { requestContent in
                let requestID = try requestContent.calculateRequestId()
                let domainSeparatedData = domain.domainSeparatedData(requestID)
                return domainSeparatedData.getSha256()
            }
            
            return signer.sign(hashes: hashes, walletPublicKey: walletPublicKey)
                .tryMap { signatures in
                    let envelopes = zip(contents, signatures).map { content, signature in
                        ICPRequestEnvelope(
                            content: content,
                            senderPubkey: data.derEncodedPublicKey,
                            senderSig: signature
                        )
                    }
                    guard envelopes.count == 2,
                          let callEnvelope = envelopes.first,
                          let readStateEnvelope = envelopes.last else {
                        throw WalletError.empty
                    }
                    return ICPSigningOutput(
                        requestID: data.callRequestID,
                        callEnvelope: callEnvelope,
                        readStateEnvelope: readStateEnvelope
                    )
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    private func requestsData(input: ICPSigningInput) throws -> ICPRequestsData {
        guard let publicKey = PublicKey(
            tangemPublicKey: walletPublicKey.blockchainKey,
            publicKeyType: CoinType.internetComputer.publicKeyType
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        let derEncodedPublicKey = try ICPCryptography.DER.encoded(publicKey.data)
        let sender = try ICPPrincipal.selfAuthenticatingPrincipal(derEncodedPublicKey: derEncodedPublicKey)
        let nonce = { try CryptoUtils.generateRandomBytes(count: 32) }
        
        let callRequestContent = makeCallRequestContent(input: input, sender: sender, nonce: try nonce())
        
        let requestID = try callRequestContent.calculateRequestId()
        
        let readStateRequestContent = makeReadStateRequestContent(
            requestID: requestID,
            sender: sender,
            nonce: try nonce()
        )
        
        return ICPRequestsData(
            derEncodedPublicKey: derEncodedPublicKey,
            callRequestID: requestID,
            callRequestContent: callRequestContent,
            readStateRequestContent: readStateRequestContent
        )
    }
    
    private func makeCallRequestContent(
        input: ICPSigningInput,
        sender: ICPPrincipal,
        nonce: Data
    ) -> ICPRequestContent {
        let method = method(from: input, sender: sender)
        let serialisedArgs = CandidSerialiser().encode(method.args)
        
        return ICPCallRequestContent(
            request_type: .call,
            sender: sender.bytes,
            nonce: nonce,
            ingress_expiry: makeIngressExpiry(),
            method_name: method.methodName,
            canister_id: method.canister.bytes,
            arg: serialisedArgs
        )
    }
    
    private func makeReadStateRequestContent(requestID: Data, sender: ICPPrincipal, nonce: Data) -> ICPReadStateRequestContent {
        let paths = ICPStateTreePath.readStateRequestPaths(requestID: requestID)
        return ICPReadStateRequestContent(
            request_type: .readState,
            sender: sender.bytes,
            nonce: nonce,
            ingress_expiry: makeIngressExpiry(),
            paths: paths.map { $0.encodedComponents() }
        )
    }
    
    private func makeIngressExpiry(_ seconds: TimeInterval = Self.defaultIngressExpirySeconds) -> Int {
        let expiryDate = Date().addingTimeInterval(seconds)
        let nanoSecondsSince1970 = expiryDate.timeIntervalSince1970 * 1_000_000_000
        return Int(nanoSecondsSince1970)
    }
    
    private func method(from input: ICPSigningInput, sender: ICPPrincipal) -> ICPMethod {
        ICPMethod(
            canister: ICPSystemCanisters.ledger,
            methodName: "transfer",
            args: .record([
                "from_subaccount": .option(.blob(Data(repeating: 0, count: 32))),
                "to": .blob(Data(hex: input.destination)),
                "amount": .ICPAmount(input.amount.uint64Value),
                "fee": .ICPAmount(10000),
                "memo": .natural64(input.memo ?? 0),
                "created_at_time": .ICPTimestampNow()
            ])
        )
    }
}

fileprivate struct ICPRequestsData {
    let derEncodedPublicKey: Data
    let callRequestID: Data
    let callRequestContent: ICPRequestContent
    let readStateRequestContent: ICPRequestContent
}

struct ICPSigningOutput {
    let requestID: Data
    let callEnvelope: ICPRequestEnvelope
    let readStateEnvelope: ICPRequestEnvelope
}
