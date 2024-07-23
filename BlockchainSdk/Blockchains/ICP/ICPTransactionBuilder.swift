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
    
    private let blockchain: Blockchain
    
    // MARK: - Init
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    // MARK: - Implementation
    
    /// Build input for sign transaction
    /// - Parameters:
    ///   - transaction: Transaction
    ///   - date: current timestamp
    /// - Returns: ICPSigningInput for sign transaction with external signer
    public func buildForSign(
        transaction: Transaction,
        date: Date = Date()
    ) throws -> ICPSigningInput {
        ICPSigningInput(
            destination: Data(hex: transaction.destinationAddress),
            amount: (transaction.amount.value * blockchain.decimalValue).uint64Value,
            date: date
        )
    }
    
    /// Build for send transaction obtain external message output
    /// - Parameters:
    ///   - ouput: IcpKit provided request envelope
    /// - Returns: cbor-encoded transaction Data
    public func buildForSend<T: ICPRequestContent>(output: ICPRequestEnvelope<T>) throws -> Data {
        try output.cborEncoded()
    }
}
