//
//  ChiaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Bls_Signature

final class ChiaTransactionBuilder {
    // MARK: - Public Properties
    
    var unspentCoins: [ChiaCoin]
    
    // MARK: - Private Properties
    
    private let blockchain: Blockchain
    private let walletPublicKey: Data
    private var coinSpends: [ChiaCoinSpend] = []
    
    private var genesisChallenge: Data {
        Data(hex: GenesisChallenge.challenge(isTestnet: blockchain.isTestnet))
    }
    
    // MARK: - Init
    
    init(blockchain: Blockchain, walletPublicKey: Data, unspentCoins: [ChiaCoin] = []) {
        self.blockchain = blockchain
        self.walletPublicKey = walletPublicKey
        self.unspentCoins = unspentCoins
    }
    
    // MARK: - Implementation
    
    func buildForSign(transaction: Transaction) throws -> [Data] {
        guard !unspentCoins.isEmpty else {
            throw WalletError.failedToBuildTx
        }
        
        let change = try calculateChange(
            transaction: transaction,
            unspentCoins: unspentCoins
        )
        
        coinSpends = try toChiaCoinSpends(
            change: change,
            destination: transaction.destinationAddress,
            source: transaction.sourceAddress,
            amount: transaction.amount
        )
        
        let hashesForSign = try coinSpends.map {
            let solutionHash = try ClvmProgram.Decoder(
                programBytes: Data(hex: $0.solution).dropFirst(1).dropLast(1).bytes
            ).deserialize().hash()

            return try (solutionHash + $0.coin.calculateId() + genesisChallenge).hashAugScheme(with: walletPublicKey)
        }
        
        return hashesForSign
    }
    
    func buildToSend(signatures: [Data]) throws -> ChiaSpendBundle {
        let aggregatedSignature = try BlsSignatureSwift.aggregate(signatures: signatures.map { $0.hexString })
        
        return ChiaSpendBundle(
            aggregatedSignature: aggregatedSignature,
            coinSpends: coinSpends
        )
    }
    
    /// Calculate standart costs for fee transaction
    /// - Parameter amount: Amount of send transaction
    /// - Returns: Sum value for transaction
    func getTransactionCost(amount: Amount) -> Int64 {
        let decimalAmount = amount.value / blockchain.decimalValue
        let decimalBalance = unspentCoins.map { Decimal($0.amount) }.reduce(0, +)
        let change = decimalBalance - decimalAmount
        let numberOfCoinsCreated: Int = change > 0 ? 2 : 1

        return Int64((coinSpends.count * CostConstants.COIN_SPEND_COST) + (numberOfCoinsCreated * CostConstants.CREATE_COIN_COST))
    }
    
    // MARK: - Private Implementation
    
    private func calculateChange(transaction: Transaction, unspentCoins: [ChiaCoin]) throws -> Int64 {
        let fullAmount = unspentCoins.map { $0.amount }.reduce(0, +)
        let transactionAmount = transaction.amount.value * blockchain.decimalValue
        let transactionFeeAmount = transaction.fee.amount.value * blockchain.decimalValue
        let changeAmount = fullAmount - (transactionAmount.int64Value + transactionFeeAmount.int64Value)
        
        return changeAmount
    }
    
    private func toChiaCoinSpends(change: Int64, destination: String, source: String, amount: Amount) throws -> [ChiaCoinSpend] {
        var coinSpends = unspentCoins.map {
            ChiaCoinSpend(
                coin: $0,
                puzzleReveal: ChiaPuzzleUtils().getPuzzleHash(from: walletPublicKey).hex,
                solution: ""
            )
        }
        
        let sendCondition = try createCoinCondition(for: destination, with: amount.value.int64Value)
        let changeCondition = try change != 0 ? createCoinCondition(for: source, with: change) : nil
        
        let solution: [ChiaCondition] = [sendCondition, changeCondition].compactMap { $0 }
        coinSpends[0].solution = try solution.toSolution().hex
        
        for coinSpend in coinSpends.dropFirst(1) {
            coinSpend.solution = try [RemarkCondition()].toSolution().hex
        }

        return coinSpends
    }
    
    private func createCoinCondition(for address: String, with change: Int64) throws -> CreateCoinCondition {
        return try CreateCoinCondition(
            destinationPuzzleHash: ChiaPuzzleUtils().getPuzzleHash(from: address),
            amount: change
        )
    }
    
}

// MARK: - Constants

fileprivate extension ChiaTransactionBuilder {
    enum CostConstants {
        static let COIN_SPEND_COST: Int = 4500000
        static let CREATE_COIN_COST: Int = 2400000
    }
    
    enum GenesisChallenge {
        private static let mainnet = "ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb"
        private static let testnet = "ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2"
        
        static func challenge(isTestnet: Bool) -> String {
            return isTestnet ? testnet : mainnet
        }
    }
}

// MARK: - Helpers

fileprivate extension Array where Element == ChiaCondition {
    func toSolution() throws -> Data {
        let conditions = ClvmProgram.from(list: map { $0.toProgram() })
        let solutionArguments = ClvmProgram.from(list: [conditions]) // might be more than one for other puzzles

        return try solutionArguments.serialize()
    }
}

fileprivate extension Data {
    func hashAugScheme(with publicKey: Data) throws -> Data {
        try Data(hex: BlsSignatureSwift.augSchemeMplG2Map(publicKey: publicKey.hex, message: self.hex))
    }
}
