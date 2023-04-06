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
    
    /// Only TrustWallet signer input transfer key (not for use public implementation)
    private var inputPrivateKey: Curve25519.Signing.PrivateKey
    
    private var modeTransactionConstant: UInt32 {
        UInt32(TheOpenNetworkSendMode.payFeesSeparately.rawValue | TheOpenNetworkSendMode.ignoreActionPhaseErrors.rawValue)
    }
    
    // MARK: - Init
    
    init(wallet: Wallet) {
        self.wallet = wallet
        self.inputPrivateKey = .init()
    }
    
    // MARK: - Implementation
    
    /// Build input for sign transaction from Parameters
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: TheOpenNetworkSigningInput for sign transaction with external signer
    public func buildForSign(amount: Amount, destination: String, memo: TONTransactionParams.Memo? = nil) throws -> TheOpenNetworkSigningInput {
        return try self.input(amount: amount, destination: destination, memo: memo)
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
    private func input(amount: Amount, destination: String, memo: TONTransactionParams.Memo?) throws -> TheOpenNetworkSigningInput {
        let transfer = try self.transfer(amount: amount, destination: destination, memo: memo)
        
        // Sign input with dummy key of Curve25519 private key
        let input = TheOpenNetworkSigningInput.with {
            $0.transfer = transfer
            $0.privateKey = inputPrivateKey.rawRepresentation
        }
        
        return input
    }
    
    /// Create transfer message transaction to blockchain
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: TheOpenNetworkTransfer message for Input transaction of TON blockchain
    private func transfer(amount: Amount, destination: String, memo: TONTransactionParams.Memo?) throws -> TheOpenNetworkTransfer {
        TheOpenNetworkTransfer.with {
            $0.walletVersion = TheOpenNetworkWalletVersion.walletV4R2
            $0.dest = destination
            $0.amount = ((amount.value * wallet.blockchain.decimalValue) as NSDecimalNumber).uint64Value
            $0.sequenceNumber = UInt32(sequenceNumber)
            $0.mode = modeTransactionConstant
            $0.bounceBehavior = .nonBounceable
            $0.comment = memo?.value ?? ""
         }
    }
    
}

// MARK: - Dummy Cases

extension TONTransactionBuilder {
    
    public struct DummyInput {
        let wallet: Wallet
        let inputPrivateKey: Curve25519.Signing.PrivateKey
        let sequenceNumber: Int
    }
    
    /// Use only dummy tested or any dummy cases!
    static func makeDummyBuilder(with input: DummyInput) -> TONTransactionBuilder {
        let txBuilder = TONTransactionBuilder(wallet: input.wallet)
        txBuilder.inputPrivateKey = input.inputPrivateKey
        txBuilder.sequenceNumber = input.sequenceNumber
        return txBuilder
    }
    
}
