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

final class ICPTransactionBuilder {
    /// Only TrustWallet signer input transfer key (not for use public implementation)
    private var inputPrivateKey: Curve25519.Signing.PrivateKey = .init()
    
    // MARK: - Private Properties
    
    private let wallet: Wallet
    
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
    /// - Returns: InternetComputerSigningInput for sign transaction with external signer
    public func buildForSign(
        amount: Amount,
        destination: String
    ) throws -> InternetComputerSigningInput {
        InternetComputerSigningInput.with {
            $0.privateKey = inputPrivateKey.rawRepresentation
            $0.transaction = InternetComputerTransaction.with {
                $0.transfer = InternetComputerTransaction.Transfer.with {
                    $0.toAccountIdentifier = destination
                    $0.amount = (amount.value * wallet.blockchain.decimalValue).uint64Value
                    $0.memo = 0
                    $0.currentTimestampNanos = UInt64(Date().timeIntervalSince1970)
                }
            }
        }
    }
    
    /// Build for send transaction obtain external message output
    /// - Parameters:
    ///   - input: TW output of message
    /// - Returns: InternetComputerSigningOutput for ICP blockchain
    public func buildForSend(input: InternetComputerSigningInput) throws -> InternetComputerSigningOutput {
        AnySigner.sign(input: input, coin: .internetComputer)
    }
}
