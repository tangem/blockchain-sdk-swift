//
//  Stellart=TransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine

@available(iOS 13.0, *)
class StellarTransactionBuilder {
    public var sequence: Int64?
    var useTimebounds = true
    //for tests
    var specificTxTime: TimeInterval? = nil
    
    private let stellarSdk: StellarSDK
    private let walletPublicKey: Data
    private let isTestnet: Bool
    
    init(stellarSdk: StellarSDK, walletPublicKey: Data, isTestnet: Bool) {
        self.stellarSdk = stellarSdk
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
    
    public func buildForSign(transaction: Transaction) -> AnyPublisher<(hash: Data, transaction: stellarsdk.TransactionXDR), Error> {
        guard let destinationKeyPair = try? KeyPair(accountId: transaction.destinationAddress),
            let sourceKeyPair = try? KeyPair(accountId: transaction.sourceAddress) else {
            return Fail(error: WalletError.failedToBuildTx)
                .eraseToAnyPublisher()
        }
        
        let memo = (transaction.params as? StellarTransactionParams)?.memo ?? Memo.text("")
        
        return stellarSdk.accounts.checkTargetAccount(address: transaction.destinationAddress, token: transaction.amount.type.token)
            .tryMap { [weak self] response -> (hash: Data, transaction: stellarsdk.TransactionXDR) in
                guard let self = self else { throw WalletError.empty }
                
                let isAccountCreated = response.accountCreated
                
                if transaction.amount.type == .coin {
                    if !isAccountCreated && transaction.amount.value < 1 {
                        throw StellarError.xlmCreateAccount
                    }
                    
                    let operation = isAccountCreated ? try PaymentOperation(sourceAccountId: transaction.sourceAddress,
                                                                            destinationAccountId: transaction.destinationAddress,
                                                                            asset: Asset(type: AssetType.ASSET_TYPE_NATIVE)!,
                                                                            amount: transaction.amount.value ) :
                        CreateAccountOperation(sourceAccountId: nil, destination: destinationKeyPair, startBalance: transaction.amount.value)
                    
                    return try self.serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: memo)
                    
                } else if transaction.amount.type.isToken {
                    guard let contractAddress = transaction.contractAddress, let keyPair = try? KeyPair(accountId: contractAddress),
                          let asset = self.createNonNativeAsset(code: transaction.amount.currencySymbol, issuer: keyPair) else {
                        throw WalletError.failedToBuildTx
                    }
                    
                    guard isAccountCreated else {
                        throw StellarError.assetNoAccountOnDestination
                    }
                    
                    guard response.trustlineCreated  else {
                        throw StellarError.assetNoTrustline
                    }
                    
                    if  transaction.amount.value > 0 {
                        
                        let operation = try PaymentOperation(sourceAccountId: transaction.sourceAddress,
                                                             destinationAccountId: transaction.destinationAddress,
                                                             asset: asset,
                                                             amount: transaction.amount.value)
                        
                        return try self.serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: memo)
                    } else {
                        guard let changeTrustAsset = asset.toChangeTrustAsset() else {
                            throw WalletError.failedToBuildTx
                        }
                        
                        let operation = ChangeTrustOperation(sourceAccountId: transaction.sourceAddress, asset: changeTrustAsset, limit: Decimal(string: "900000000000.0000000"))
                        return try self.serializeOperation(operation, sourceKeyPair: sourceKeyPair, memo: memo)
                    }
                    
                } else {
                    throw WalletError.failedToBuildTx
                }
            }
            .eraseToAnyPublisher()
    }
    
    public func buildForSend(signature: Data, transaction: TransactionXDR) -> String? {
        var transaction = transaction
        let hint = walletPublicKey.suffix(4)
        let decoratedSignature = DecoratedSignatureXDR(hint: WrappedData4(hint), signature: signature)
        transaction.addSignature(signature: decoratedSignature)
        let envelope = try? transaction.encodedEnvelope()
        return envelope
    }
    
    
    private func createNonNativeAsset(code: String, issuer: KeyPair) -> Asset? {
        if code.count >= 1 && code.count <= 4 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM4, code: code, issuer: issuer)
        } else if code.count >= 5 && code.count <= 12 {
            return Asset(type: AssetType.ASSET_TYPE_CREDIT_ALPHANUM12, code: code, issuer: issuer)
        } else {
            return nil
        }
    }
    
    private func serializeOperation(_ operation: stellarsdk.Operation, sourceKeyPair: KeyPair, memo: Memo) throws -> (hash: Data, transaction: stellarsdk.TransactionXDR) {
        guard let xdrOperation = try? operation.toXDR(),
            let seqNumber = sequence else {
            throw WalletError.failedToBuildTx
        }
        
        let currentTime = specificTxTime ?? Date().timeIntervalSince1970
        let minTime = currentTime - 60.0
        let maxTime = currentTime + 60.0
        
        let tx = TransactionXDR(sourceAccount: sourceKeyPair.publicKey,
                                seqNum: seqNumber + 1,
                                timeBounds: useTimebounds ? TimeBoundsXDR(minTime: UInt64(minTime), maxTime: UInt64(maxTime)): nil,
                                memo: memo.toXDR(),
                                operations: [xdrOperation])
        
        let network = isTestnet ? Network.testnet : Network.public
        guard let hash = try? tx.hash(network: network) else {
            throw WalletError.failedToBuildTx
        }
        
        return (hash, tx)
    }
}

extension Asset {
    func toChangeTrustAsset() -> ChangeTrustAsset? {
        ChangeTrustAsset(type: self.type, code: self.code, issuer: self.issuer)
    }
}
