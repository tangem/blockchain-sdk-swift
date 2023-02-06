//
//  TONTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Transaction builder for TON wallet
struct TONTransactionBuilder {
    
    // MARK: - Properties
    
    /// Sequence number of transactions
    var seqno: Int = 0
    
    // MARK: - Private Properties
    
    private var blockchain: Blockchain
    private var wallet: TONWallet?
    
    // MARK: - Init
    
    init(wallet: Wallet) throws {
        self.wallet = try .init(publicKey: wallet.publicKey.blockchainKey)
        self.blockchain = wallet.blockchain
    }
    
    init(publicKey: Data, blockchain: Blockchain) throws {
        self.wallet = try .init(publicKey: publicKey)
        self.blockchain = blockchain
    }
    
    // MARK: - Implementation
    
    /// Build external message TON blockchain for estimate fee with dummy signature
    /// - Parameters:
    ///   - amount: Amount of transaction
    ///   - destination: Destination transaction
    /// - Returns: External message for TON blockchain
    public func buildForEstimateFee(amount: Amount, destination: String) throws -> TONExternalMessage {
        guard let signingMessage = try self.wallet?.createTransferMessage(
            address: destination,
            amount: ((amount.value * blockchain.decimalValue) as NSDecimalNumber).uintValue,
            seqno: seqno,
            dummySignature: true
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        guard let externalMessage = try self.wallet?.createExternalMessage(
            signingMessage: signingMessage,
            signature: [UInt8](repeating: 0, count: 64),
            seqno: seqno
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        return externalMessage
    }
    
    /// Build for sign transaction in form TON Cell
    /// - Parameters:
    ///   - transaction: Transaction model
    /// - Returns: Blockchain Cell
    public func buildForSign(transaction: Transaction) throws -> TONCell {
        guard let signingMessage = try self.wallet?.createTransferMessage(
            address: transaction.destinationAddress,
            amount: ((transaction.amount.value * blockchain.decimalValue) as NSDecimalNumber).uintValue,
            seqno: seqno
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        return signingMessage
    }
    
    /// Build for send transaction with signed signature and execute TON external message
    /// - Parameters:
    ///   - signingMessage: Message for signing
    ///   - signature: Signature of signing
    /// - Returns: External message for TON blockchain
    public func buildForSend(signingMessage: TONCell, signature: Data) throws -> TONExternalMessage {
        guard let externalMessage = try self.wallet?.createExternalMessage(
            signingMessage: signingMessage,
            signature: signature.bytes,
            seqno: seqno
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        return externalMessage
    }
    
}
