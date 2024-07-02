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
    ) throws -> InternetComputerSigningInput {
        InternetComputerSigningInput.with {
            $0.privateKey = inputPrivateKey.privateKey
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
    
    public func buildForSendOld(
        output: InternetComputerSigningOutput
    ) -> Data {
        output.signedTransaction
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
                        requestID: try data.callRequestContent.calculateRequestId(),
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
        
        let method = method(from: input)
        let serialisedArgs = CandidSerialiser().encode(method.args)
        let callRequest = ICPRequest.call(method)
        
        let nonce = { try CryptoUtils.generateRandomBytes(count: 32) }
        
        let callRequestContent = ICPCallRequestContent(
            request_type: .from(callRequest),
            sender: sender.bytes,
            nonce: try nonce(),
            ingress_expiry: createIngressExpiry(),
            method_name: method.methodName,
            canister_id: method.canister.bytes,
            arg: serialisedArgs
        )
        
        let requestID = try callRequestContent.calculateRequestId()
        
        let paths: [ICPStateTreePath] = [
            ["time"],
            ["request_status", .data(requestID), "status"],
            ["request_status", .data(requestID), "reply"],
            ["request_status", .data(requestID), "reject_code"],
            ["request_status", .data(requestID), "reject_message"]
        ].map { ICPStateTreePath($0) }
        
        let readStateRequest = ICPRequest.readState(paths: paths)
        let readStateRequestContent = ICPReadStateRequestContent(
            request_type: .from(readStateRequest),
            sender: sender.bytes,
            nonce: try nonce(),
            ingress_expiry: createIngressExpiry(),
            paths: paths.map { $0.encodedComponents() }
        )
        
        return ICPRequestsData(
            derEncodedPublicKey: derEncodedPublicKey,
            callRequestContent: callRequestContent,
            readStateRequestContent: readStateRequestContent
        )
    }
    
    private func createIngressExpiry(_ seconds: TimeInterval = Self.defaultIngressExpirySeconds) -> Int {
        let expiryDate = Date().addingTimeInterval(seconds)
        let nanoSecondsSince1970 = expiryDate.timeIntervalSince1970 * 1_000_000_000
        return Int(nanoSecondsSince1970)
    }
    
    private func method(from input: ICPSigningInput) -> ICPMethod {
        ICPMethod(
            canister: ICPSystemCanisters.ledger,
            methodName: "send_pb",
            args: .record([
                "from_subaccount": .option(.blob(Data(hex: input.source))),
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
    let callRequestContent: ICPRequestContent
    let readStateRequestContent: ICPRequestContent
}

struct ICPSigningOutput {
    let requestID: Data
    let callEnvelope: ICPRequestEnvelope
    let readStateEnvelope: ICPRequestEnvelope
}
