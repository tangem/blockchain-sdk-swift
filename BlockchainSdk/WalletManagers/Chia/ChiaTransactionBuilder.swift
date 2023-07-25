//
//  ChiaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import ChiaBLS

final class ChiaTransactionBuilder {
    // MARK: - Public Properties
    
    var unspentCoins: [ChiaCoin]
    
    // MARK: - Private Properties
    
    private let isTestnet: Bool
    private let walletPublicKey: Data
    private var coinSpends: [ChiaCoinSpend] = []
    
    private var genesisChallenge: Data {
        Data(hex: ChiaConstant.genesisChallenge(isTestnet: isTestnet))
    }
    
    // MARK: - Init
    
    init(isTestnet: Bool, walletPublicKey: Data, unspentCoins: [ChiaCoin] = []) {
        self.isTestnet = isTestnet
        self.walletPublicKey = walletPublicKey
        self.unspentCoins = unspentCoins
    }
    
    // MARK: - Implementation
    
    /// Build input for sign transaction from Parameters
    /// - Parameters:
    ///   - amount: Amount transaction
    ///   - destination: Destination address transaction
    /// - Returns: Array of bytes for transaction
    func buildForSign(transaction: Transaction) throws -> [Data] {
        guard !unspentCoins.isEmpty else {
            throw WalletError.failedToBuildTx
        }
        
        let change = try calculateChange(
            transaction: transaction,
            unspentCoins: unspentCoins
        )
        
        let coinSpends = try toChiaCoinSpends(
            change: change,
            destination: transaction.destinationAddress,
            source: transaction.sourceAddress,
            amount: transaction.amount
        )
        
        let hashesForSign = try coinSpends.map {
            let solutionHash = try ClvmProgram.Decoder(
                programBytes: Data(hex: $0.solution).dropFirst(1).dropLast(1).bytes
            ).deserialize().hash()

            return try (solutionHash + $0.coin.calculateId() + genesisChallenge).hashAugScheme()
        }
        
        return hashesForSign
    }
    
    func buildToSend(signatures: Data) throws -> ChiaTransactionBody {
        let aggregatedSignature = try ChiaBLS.aggregate(signatures: signatures.map { $0.hexString })

        return ChiaTransactionBody(
            spendBundle: ChiaSpendBundle(
                aggregatedSignature: aggregatedSignature,
                coinSpends: coinSpends
            )
        )
    }
    
    // MARK: - Private Implementation
    
    private func calculateChange(transaction: Transaction, unspentCoins: [ChiaCoin]) throws -> Int64 {
        let fullAmount = unspentCoins.map { $0.amount }.reduce(0, +)
        return fullAmount - (transaction.amount.value.int64Value + transaction.fee.amount.value.int64Value)
    }
    
    private func toChiaCoinSpends(change: Int64, destination: String, source: String, amount: Amount) throws -> [ChiaCoinSpend] {
        let coinSpends = unspentCoins.map {
            ChiaCoinSpend(
                coin: $0,
                puzzleReveal: ChiaConstant.getPuzzle(walletPublicKey: walletPublicKey).hex,
                solution: ""
            )
        }
        
        let sendCondition = try createCoinCondition(for: destination, with: amount.value.int64Value)
        let changeCondition = try change != 0 ? createCoinCondition(for: source, with: change) : nil
        
        self.coinSpends[0].solution = try [sendCondition, changeCondition].compactMap { $0 }.toSolution().hex
        
        for var coinSpend in coinSpends.dropFirst(1) {
            coinSpend.solution = try [RemarkCondition()].toSolution().hex
        }

        return coinSpends
    }
    
    private func createCoinCondition(for address: String, with change: Int64) throws -> CreateCoinCondition {
        return try CreateCoinCondition(
            destinationPuzzleHash: ChiaConstant.getPuzzleHash(address: address),
            amount: change
        )
    }
    
}
