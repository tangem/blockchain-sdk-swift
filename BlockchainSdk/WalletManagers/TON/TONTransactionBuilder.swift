//
//  TONTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

/// Transaction builder for TON wallet
struct TONTransactionBuilder {
    
    // MARK: - Properties
    
    /// Sequence number of transactions
    var seqno: Int = 0
    
    // MARK: - Private Properties
    
    private var wallet: Wallet
    
    // MARK: - Init
    
    init(wallet: Wallet) throws {
        self.wallet = wallet
    }
    
    // MARK: - Implementation
    
    /// Build external message TON blockchain for estimate fee with dummy signature
    /// - Parameters:
    ///   - amount: Amount of transaction
    ///   - destination: Destination transaction
    /// - Returns: External message for TON blockchain
    public func buildForEstimateFee(amount: Amount, destination: String) throws -> Data {
        TransactionCompiler.buildInput(
            coinType: .ton,
            from: wallet.address,
            to: destination,
            amount: "0.01",
            asset: "",
            memo: "",
            chainId: ""
        )
    }
    
    /// Build for sign transaction in form TON Cell
    /// - Parameters:
    ///   - transaction: Transaction model
    /// - Returns: Blockchain Cell
    public func buildForSign(transaction: Transaction) throws -> Data {
        return Data()
    }
    
    /// Build for send transaction with signed signature and execute TON external message
    /// - Parameters:
    ///   - signingMessage: Message for signing
    ///   - signature: Signature of signing
    /// - Returns: External message for TON blockchain
    public func buildForSend(signingMessage: Data, signature: Data) throws -> Data {
        return Data()
    }
    
}
