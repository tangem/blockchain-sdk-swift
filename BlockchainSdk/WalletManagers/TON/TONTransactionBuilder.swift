//
//  TONTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import WalletCore

/// Transaction builder for TON wallet
final class TONTransactionBuilder {
    
    // MARK: - Properties
    
    /// Sequence number of transactions
    var sequenceNumber: Int = 0
    
    // MARK: - Private Properties
    
    private let wallet: Wallet
    
    private var modeTransactionConstant: UInt32 {
        UInt32(TheOpenNetworkSendMode.payFeesSeparately.rawValue | TheOpenNetworkSendMode.ignoreActionPhaseErrors.rawValue)
    }
    
    // MARK: - Init
    
    init(wallet: Wallet) {
        self.wallet = wallet
    }
    
    // MARK: - Implementation
    
    /// Build input for sign transaction from Parameters
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: TheOpenNetworkSigningInput for sign transaction with external signer
    public func buildForSign(amount: Amount, destination: String) throws -> TheOpenNetworkSigningInput {
        return try self.input(amount: amount, destination: destination)
    }
    
    /// Build for send transaction obtain external message output
    /// - Parameters:
    ///   - output: TW output of message
    /// - Returns: External message for TON blockchain
    public func buildForSend(output: TheOpenNetworkSigningOutput) throws -> String {
        return output.encoded
    }
    
    // MARK: - Private Implementation
    
    /// Build WalletCore input for sign transaction
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: TheOpenNetworkSigningInput for sign transaction with external signer
    private func input(amount: Amount, destination: String) throws -> TheOpenNetworkSigningInput {
        let transfer = try self.transfer(amount: amount, destination: destination)
        
        // Sign input with dummy key of Curve25519 private key
        let input = TheOpenNetworkSigningInput.with {
            $0.transfer = transfer
            $0.privateKey = Curve25519.Signing.PrivateKey().rawRepresentation
        }
        
        return input
    }
    
    /// Create transfer message transaction to blockchain
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: TheOpenNetworkTransfer message for Input transaction of TON blockchain
    private func transfer(amount: Amount, destination: String) throws -> TheOpenNetworkTransfer {
        TheOpenNetworkTransfer.with {
            $0.walletVersion = TheOpenNetworkWalletVersion.walletV4R2
            $0.dest = destination
            $0.amount = ((amount.value * wallet.blockchain.decimalValue) as NSDecimalNumber).uint64Value
            $0.sequenceNumber = UInt32(sequenceNumber)
            $0.mode = modeTransactionConstant
         }
    }
    
}
