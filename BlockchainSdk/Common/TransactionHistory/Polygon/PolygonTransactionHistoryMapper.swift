//
//  PolygonTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct PolygonTransactionHistoryMapper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    private func mapAmount(from transaction: PolygonTransactionHistoryResult.Transaction, amountType: Amount.AmountType) -> Decimal? {
        guard let transactionValue = Decimal(stringValue: transaction.value) else {
            return nil
        }

        let decimalValue: Decimal
        switch amountType {
        case .coin, .reserve:
            decimalValue = blockchain.decimalValue
        case .token(let value):
            decimalValue = value.decimalValue
        }

        return transactionValue / decimalValue
    }

    private func mapFee(_ transaction: PolygonTransactionHistoryResult.Transaction) -> Fee {
        guard
            let gasUsed = Decimal(stringValue: transaction.gasUsed),
            let gasPrice = Decimal(stringValue: transaction.gasPrice)
        else {
            Log.log("Transaction with missed/invalid fee \(transaction) received")
            return Fee(.zeroCoin(for: blockchain))
        }

        let feeValue = gasUsed * gasPrice / blockchain.decimalValue
        let feeAmount = Amount(with: blockchain, value: feeValue)

        return Fee(feeAmount)
    }

    private func mapStatus(_ transaction: PolygonTransactionHistoryResult.Transaction) -> TransactionRecord.TransactionStatus {
        if transaction.isError?.isBooleanTrue == true {
            return .failed
        }

        if transaction.txreceiptStatus?.isBooleanTrue == true {
            return .confirmed
        }

        return .unconfirmed
    }

    private func mapType(_ transaction: PolygonTransactionHistoryResult.Transaction) -> TransactionRecord.TransactionType {
        if transaction.isContractInteraction {
            return .contractMethod(id: transaction.functionName ?? "")
        }

        return .transfer
    }

    private func mapToAPIError(_ result: PolygonTransactionHistoryResult) -> PolygonScanAPIError {
        switch result.result {
        case .description(let description) where description.lowercased().starts(with: Constants.maxRateLimitReachedResultPrefix):
            return .maxRateLimitReached
        case .transactions(let transactions) where transactions.isEmpty:
            // There is no `totalPageCount` or similar field in the PolygonScan transaction history API,
            // so we determine the end of the transaction history by receiving an empty response
            return .endOfTransactionHistoryReached
        default:
            return .unknown
        }
    }
}

// MARK: - TransactionHistoryMapper protocol conformance

extension PolygonTransactionHistoryMapper: TransactionHistoryMapper {
    func mapToTransactionRecords(
        _ response: PolygonTransactionHistoryResult,
        walletAddress: String,
        amountType: Amount.AmountType
    ) throws -> TransactionHistory.Response {
        guard response.status.isBooleanTrue else {
            throw mapToAPIError(response)
        }

        let transactions = response.result.transactions ?? []
        let transactionRecords = transactions.compactMap { transaction -> TransactionRecord? in
            let sourceAddress = transaction.from
            let destinationAddress = transaction.to

            guard sourceAddress.caseInsensitiveEquals(to: walletAddress) || destinationAddress.caseInsensitiveEquals(to: walletAddress) else {
                Log.log("Unrelated transaction \(transaction) received")
                return nil
            }

            guard let transactionAmount = mapAmount(from: transaction, amountType: amountType) else {
                Log.log("Transaction with invalid value \(transaction) received")
                return nil
            }

            let isOutgoing = sourceAddress.caseInsensitiveEquals(to: walletAddress)

            let source = TransactionRecord.Source(
                address: sourceAddress,
                amount: transactionAmount
            )

            let destination = TransactionRecord.Destination(
                address: transaction.isContractInteraction ? .contract(destinationAddress) : .user(destinationAddress),
                amount: transactionAmount
            )

            guard let timeStamp = TimeInterval(transaction.timeStamp) else {
                Log.log("Transaction with invalid timeStamp \(transaction) received")
                return nil
            }

            return TransactionRecord(
                hash: transaction.hash,
                source: .single(source),
                destination: .single(destination),
                fee: mapFee(transaction),
                status: mapStatus(transaction),
                isOutgoing: isOutgoing,
                type: mapType(transaction),
                date: Date(timeIntervalSince1970: timeStamp),
                tokenTransfers: []
            )
        }

        return TransactionHistory.Response(records: transactionRecords)
    }
}

// MARK: - Constants

private extension PolygonTransactionHistoryMapper {
    enum Constants {
        static let maxRateLimitReachedResultPrefix = "max rate limit reached"
    }
}

// MARK: - Convenience extensions

private extension PolygonTransactionHistoryResult.Transaction {
    var isContractInteraction: Bool {
        return contractAddress?.nilIfEmpty != nil || functionName?.nilIfEmpty != nil
    }
}

private extension PolygonTransactionHistoryResult.Result {
    var transactions: [PolygonTransactionHistoryResult.Transaction]? {
        if case .transactions(let transactions) = self {
            return transactions
        }

        return nil
    }

    var description: String? {
        if case .description(let description) = self {
            return description
        }

        return nil
    }
}

private extension String {
    var isBooleanTrue: Bool {
        return Int(self) == 1
    }
}
