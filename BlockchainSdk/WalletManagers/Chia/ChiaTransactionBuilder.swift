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
    // MARK: - Public Properties
    
    var unspentCoins: [ChiaCoin]
    
    // MARK: - Private Properties
    
    private let walletPublicKey: Data
    private var coinSpends: [ChiaCoinSpend] = []
    
    // MARK: - Init
    
    init(walletPublicKey: Data, unspentCoins: [ChiaCoin] = []) {
        self.walletPublicKey = walletPublicKey
        self.unspentCoins = unspentCoins
    }
    
    // MARK: - Implementation
    
    /// Build input for sign transaction from Parameters
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: Array of bytes for transaction
    func buildForSign(transaction: Transaction) throws -> Data {
        guard !unspentCoins.isEmpty else {
            throw WalletError.failedToBuildTx
        }
        
        let change = try calculateChange(transaction: transaction, unspentCoins: unspentCoins)
        let coinSpends = try toChiaCoinSpends(change: change, destination: transaction.destinationAddress, amount: transaction.amount)
        
        let hashesForSign = coinSpends.map { _ in
//            let solutionHash = ClvmNode.Decoder(
//                programBytes: Data(hex: $0.solution).dro .hexToBytes().drop(1).dropLast(1).toByteArray()
//            ).deserialize().hash()

//            (solutionHash + it.coin.calculateId() + genesisChallenge).hashAugScheme()
//            return Data()
        }
        
//        return Data(hashesForSign)
        
        return Data()
    }
    
    func buildToSend(signatures: Data) throws -> ChiaTransactionBody {
        throw WalletError.empty
    }
    
    // MARK: - Private Implementation
    
    private func toChiaCoinSpends(change: Int64, destination: String, amount: Amount) throws -> [ChiaCoinSpend] {
        let coinSpends = unspentCoins.map {
            ChiaCoinSpend(coin: $0, puzzleReveal: ChiaConstant.getPuzzle(walletPublicKey: walletPublicKey).hex, solution: "")
        }
        
        let sendCondition = try CreateCoinCondition(
            destinationPuzzleHash: ChiaConstant.getPuzzleHash(address: destination),
            amount: amount.value.int64Value
        )
        
        throw WalletError.empty
    }
    
    private func calculateChange(transaction: Transaction, unspentCoins: [ChiaCoin]) throws -> Int64 {
        let fullAmount = unspentCoins.map { $0.amount }.reduce(0, +)
        return fullAmount - (transaction.amount.value.int64Value + transaction.fee.amount.value.int64Value)
    }
    
}

extension ChiaCoin {
    
    private func calculateId() -> Data {
        return Data()
//        parentCoinInfo.hexadecimal + puzzleHash.hexadecimal + amount.
    }
    
}
