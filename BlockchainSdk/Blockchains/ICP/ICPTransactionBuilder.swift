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
import IcpKit
import Combine
import TangemSdk

final class ICPTransactionBuilder {
    // MARK: - Private Properties
    
    private let wallet: Wallet
    
    // MARK: - Init
    
    init(wallet: Wallet) {
        self.wallet = wallet
    }
    
    // MARK: - Implementation
    
    /// Build input for sign transaction from Parameters
    /// - Parameters:
    ///   - transaction: Transaction
    /// - Returns: ICPSigningInput for sign transaction with external signer
    public func buildForSign(
        transaction: Transaction
    ) throws -> ICPSigningInput {
        ICPSigningInput(
            destination: Data(hex: transaction.destinationAddress),
            amount: (transaction.amount.value * wallet.blockchain.decimalValue).uint64Value
        )
    }
    
    /// Build for send transaction obtain external message output
    /// - Parameters:
    ///   - input: TW output of message
    /// - Returns: InternetComputerSigningOutput for ICP blockchain
    public func buildForSend<T: ICPRequestContent>(output: ICPRequestEnvelope<T>) throws -> Data {
        try output.cborEncoded()
    }
}
