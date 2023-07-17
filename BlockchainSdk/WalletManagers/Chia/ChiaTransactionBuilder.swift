//
//  ChiaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

final class ChiaTransactionBuilder {
    // MARK: - Properties
    
    let unspentCoins: [String]
    
    // MARK: - Init
    
    init(unspentCoins: [String] = []) {
        self.unspentCoins = unspentCoins
    }
    
    // MARK: - Implementation
    
    /// Build input for sign transaction from Parameters
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: Array of bytes for transaction
    func buildForSign(amount: Amount, destination: String) throws -> Data {
        throw WalletError.empty
    }
    
    func buildToSend(signatures: Data) throws -> ChiaTransactionBody {
        throw WalletError.empty
    }
    
    // MARK: - Private Implementation
    
    private func toChiaCoinSpends(
        unspentCoins: [ChiaCoin],
        change: Int64
    ) throws -> [ChiaCoinSpend] {
        throw WalletError.empty
    }
    
    private func calculateChange(
        amount: Amount,
        destination: String,
        unspentCoins: [String]
    ) throws -> UInt64 {
        throw WalletError.empty
    }
    
}
