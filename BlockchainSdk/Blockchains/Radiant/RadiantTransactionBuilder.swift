//
//  RadiantTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

final class RadiantTransactionBuilder {
    private let coinType: CoinType
    private let publicKey: Data
    private let walletAddress: String
    private let decimalValue: Decimal
    
    private var unspents: [BitcoinUnspentOutput] = []
    
    // MARK: - Init
    
    init(
        coinType: CoinType,
        publicKey: Data,
        decimalValue: Decimal,
        walletAddress: String
    ) {
        self.coinType = coinType
        self.publicKey = publicKey
        self.decimalValue = decimalValue
        self.walletAddress = walletAddress
    }
    
    // MARK: - Implementation
    
    func update(unspents: [BitcoinUnspentOutput]) {
        self.unspents = unspents
    }

    func buildForSign(transaction: Transaction, expirationTimestamp: UInt64) throws -> Data {
        let input = try buildInput(transaction: transaction)
        let txInputData = try input.serializedData()

        guard !txInputData.isEmpty else {
            throw WalletError.failedToBuildTx
        }

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        guard preSigningOutput.error == .ok, !preSigningOutput.data.isEmpty else {
            Log.debug("RadiantPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.data
    }

    func buildForSend(transaction: Transaction, signature: Data, expirationTimestamp: UInt64) throws -> Data {
        throw ""
    }
    
    // MARK: - Private Implementation

    private func buildInput(transaction: Transaction) throws -> BitcoinSigningInput {
        throw ""
    }
    
    private func buildUnspentTransaction(unspent: BitcoinUnspentOutput) throws -> BitcoinUnspentTransaction {
        BitcoinUnspentTransaction.with {
            $0.amount = Decimal(unspent.amount).int64Value
            $0.outPoint.index = UInt32(unspent.outputIndex)
            $0.outPoint.hash = Data.reverse(hexString: unspent.transactionHash)
//            $0.outPoint.sequence = ?
            $0.script = WalletCore.BitcoinScript.lockScriptForAddress(address: "", coin: coinType).data
        }
    }
}
