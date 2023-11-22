//
//  TronTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import class TangemSdk.Log

struct TronTransactionHistoryMapper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    private func mapCoinTransactionToTransactionRecord(
        _ transaction: BlockBookAddressResponse.Transaction,
        walletAddress: String
    ) -> TransactionRecord? {
        guard
            let sourceAddress = transaction.fromAddress,
            let destinationAddress = transaction.toAddress,
            let fees = Decimal(transaction.fees)
        else {
            Log.log("Transaction \(transaction) doesn't contain a required information")
            return nil
        }

        guard sourceAddress.caseInsensitiveEquals(to: walletAddress)
        || destinationAddress.caseInsensitiveEquals(to: walletAddress) else {
            Log.log("Unrelated transaction \(transaction) received")
            return nil
        }

        guard let transactionValue = Decimal(string: transaction.value) else {
            Log.log("Transaction with invalid value \(transaction) received")
            return nil
        }

        let decimalValue = blockchain.decimalValue
        let transactionAmount = transactionValue / decimalValue
        let fee = Fee(Amount(with: blockchain, value: fees / decimalValue))
        let isContract = false  // TODO: Andrey Fedorov - Add actual implementation
        let isOutgoing = sourceAddress.caseInsensitiveEquals(to: walletAddress)

        let source = TransactionRecord.Source(
            address: sourceAddress,
            amount: transactionValue
        )

        let destination = TransactionRecord.Destination(
            address: isContract ? .contract(destinationAddress) : .user(destinationAddress),
            amount: transactionValue
        )

        // Nownodes appends `0x` prefixes to TRON txids, so we have to strip these prefixes
        return TransactionRecord(
            hash: transaction.txid.removeHexPrefix(),
            source: .single(source),
            destination: .single(destination),
            fee: fee,
            status: status(transaction),
            isOutgoing: isOutgoing,
            type: transactionType(transaction),
            date: Date(timeIntervalSince1970: TimeInterval(transaction.blockTime)),
            tokenTransfers: tokenTransfers(transaction)
        )
    }

    private func mapTokensTransactionsToTransactionRecords(
        _ tokenTransfers: [BlockBookAddressResponse.TokenTransfer],
        token: Token,
        walletAddress: String
    ) -> [TransactionRecord] {
        // TODO: Andrey Fedorov - Add actual implementation
        return []
    }

    private func status(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionStatus {
        switch transaction.tronTXReceipt?.status {
        case .failure:
            return .failed
        case .ok:
            return .confirmed
        case .pending:
            return .unconfirmed
        case .none:
            return transaction.confirmations > 0 ? .confirmed : .unconfirmed
        }
    }

    private func transactionType(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionType {
        // TODO: Andrey Fedorov - Apparently, Tron blockchain uses different method encoding; add actual implementation
        return .transfer
    }

    private func tokenTransfers(_ transaction: BlockBookAddressResponse.Transaction) -> [TransactionRecord.TokenTransfer]? {
        guard let tokenTransfers = transaction.tokenTransfers else {
            return nil
        }

        return tokenTransfers.map { transfer -> TransactionRecord.TokenTransfer in
            let amount = Decimal(transfer.value) ?? 0
            return TransactionRecord.TokenTransfer(
                source: transfer.from,
                destination: transfer.to,
                amount: amount,
                name: transfer.name,
                symbol: transfer.symbol,
                decimals: transfer.decimals,
                contract: transfer._contract
            )
        }
    }
}

// MARK: - BlockBookTransactionHistoryMapper protocol conformance

extension TronTransactionHistoryMapper: BlockBookTransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: BlockBookAddressResponse,
        amountType: Amount.AmountType
    ) -> [TransactionRecord] {
        guard let transactions = response.transactions else {
            return []
        }

        let walletAddress = response.address

        return transactions
            .reduce(into: []) { partialResult, transaction in
                switch amountType {
                case .coin, .reserve:
                    if let record = mapCoinTransactionToTransactionRecord(transaction, walletAddress: walletAddress) {
                        partialResult.append(record)
                    }
                case .token(let token):
                    if let transfers = transaction.tokenTransfers, !transfers.isEmpty {
                        partialResult += mapTokensTransactionsToTransactionRecords(
                            transfers,
                            token: token,
                            walletAddress: walletAddress
                        )
                    }
                }
            }
    }
}
