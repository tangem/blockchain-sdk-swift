//
//  TONTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TONTransactionBuilder {
    
    // MARK: - Properties
    
    var wallet: TONWallet?
    var seqno: Int = 0
    
    // MARK: - Init
    
    init(wallet: Wallet) throws {
//        self.wallet = try .init(publicKey: wallet.publicKey.blockchainKey)
        self.wallet = try .init(publicKey: Data(hex: "995b3e6c86d4126f52a19115ea30d869da0b2e5502a19db1855eeb13081b870b"))
    }
    
    // MARK: - Implementation
    
    public func buildForDeploy() throws -> TONCell {
        guard let signingMessage = try self.wallet?.createSigningMessage(
            seqno: 0,
            expireAt: 1674850800
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        return signingMessage
    }
    
    /// Build for sign transaction in form TON Cell
    /// - Parameters:
    ///   - transaction: Transaction model
    /// - Returns: Blockchain Cell
    public func buildForSignDeploy(signingMessage: TONCell, signature: Data) throws -> TONExternalMessage {
        guard let externalMessage = try self.wallet?.createInitExternalMessage(
            signingMessage: signingMessage,
            signature: signature.bytes,
            seqno: seqno
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        return externalMessage
    }
    
    /// Build external message TON blockchain for estimate fee with dummy signature
    /// - Parameters:
    ///   - amount: Amount of transaction
    ///   - destination: Destination transaction
    /// - Returns: External message for TON blockchain
    public func buildForEstimateFee(amount: Amount, destination: String) throws -> TONExternalMessage {
        guard let signingMessage = try self.wallet?.createTransferMessage(
            address: destination,
            amount: (amount.value as NSDecimalNumber).uintValue,
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
            amount: 100,
            seqno: seqno,
            expireAt: 1675004992
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
