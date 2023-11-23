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

    private func extractTransactionInfo(
        from transaction: BlockBookAddressResponse.Transaction,
        sourceAddress: String,
        destinationAddress: String,
        walletAddress: String
    ) -> TransactionInfo? {
        guard
            sourceAddress.caseInsensitiveEquals(to: walletAddress) || destinationAddress.caseInsensitiveEquals(to: walletAddress)
        else {
            Log.log("Unrelated transaction \(transaction) received")
            return nil
        }

        guard let transactionValue = Decimal(string: transaction.value) else {
            Log.log("Transaction with invalid value \(transaction) received")
            return nil
        }

        let transactionAmount = transactionValue / blockchain.decimalValue
        let isOutgoing = sourceAddress.caseInsensitiveEquals(to: walletAddress)

        let source = TransactionRecord.Source(
            address: sourceAddress,
            amount: transactionAmount
        )

        let destination = TransactionRecord.Destination(
            address: .user(destinationAddress),
            amount: transactionAmount
        )

        return TransactionInfo(
            source: source,
            destination: destination,
            isOutgoing: isOutgoing
        )
    }

    private func extractTransactionInfos(
        from tokenTransfers: [BlockBookAddressResponse.TokenTransfer],
        token: Token,
        walletAddress: String,
        isOutgoing: Bool
    ) -> [TransactionInfo] {
        // Double check to exclude token transfers sent to self.
        // Actually, this is a feasible case, but we don't support such transfers at the moment
        let filteredTokenTransfers = tokenTransfers.filter { transfer in
            return isOutgoing
            ? transfer.from.caseInsensitiveEquals(to: walletAddress) && !transfer.to.caseInsensitiveEquals(to: walletAddress)
            : transfer.to.caseInsensitiveEquals(to: walletAddress) && !transfer.from.caseInsensitiveEquals(to: walletAddress)
        }

        let otherAddresses = isOutgoing
        ? filteredTokenTransfers.uniqueProperties(\.to)
        : filteredTokenTransfers.uniqueProperties(\.from)

        let groupedFilteredTokenTransfers = isOutgoing
        ? filteredTokenTransfers.grouped(by: \.to)
        : filteredTokenTransfers.grouped(by: \.from)

        return otherAddresses.map { otherAddress in
            let transfers = groupedFilteredTokenTransfers[otherAddress] ?? []
            // Multiple transactions between the same pair of src-dst addresses are aggregated into single `TransactionInfo`
            let value = transfers.reduce(into: Decimal.zero) { partialResult, transfer in
                guard
                    let rawValue = transfer.value,
                    let value = Decimal(string: rawValue)
                else {
                    Log.log("Token transfer \(transfer) with invalid value received")
                    return
                }

                partialResult += value
            }

            let transactionAmount = value / token.decimalValue

            let source = TransactionRecord.Source(
                address: isOutgoing ? walletAddress : otherAddress,
                amount: transactionAmount
            )

            let destination = TransactionRecord.Destination(
                address: .user(isOutgoing ? otherAddress : walletAddress),
                amount: transactionAmount
            )

            return TransactionInfo(
                source: source,
                destination: destination,
                isOutgoing: isOutgoing
            )
        }
    }

    private func mapToTransactionRecords(
        transaction: BlockBookAddressResponse.Transaction,
        transactionInfos: [TransactionInfo],
        fees: Decimal
    ) -> [TransactionRecord] {
        // Nownodes appends `0x` prefixes to TRON txids, so we have to strip these prefixes
        let hash = transaction.txid.removeHexPrefix()
        let fee = Fee(Amount(with: blockchain, value: fees / blockchain.decimalValue))
        let date = Date(timeIntervalSince1970: TimeInterval(transaction.blockTime))
        let status = status(transaction)
        let type = transactionType(transaction)
        let tokenTransfers = tokenTransfers(transaction)

        return transactionInfos.map { transactionInfo in
            return TransactionRecord(
                hash: hash,
                source: .single(transactionInfo.source),
                destination: .single(transactionInfo.destination),
                fee: fee,
                status: status,
                isOutgoing: transactionInfo.isOutgoing,
                type: type,
                date: date,
                tokenTransfers: tokenTransfers
            )
        }
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

// MARK: - Convenience types

private extension TronTransactionHistoryMapper {
    /// Intermediate model for simpler mapping.
    struct TransactionInfo {
        let source: TransactionRecord.Source
        let destination: TransactionRecord.Destination
        let isOutgoing: Bool
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
                guard
                    let sourceAddress = transaction.fromAddress,
                    let destinationAddress = transaction.toAddress,
                    let fees = Decimal(transaction.fees)
                else {
                    Log.log("Transaction \(transaction) doesn't contain a required information")
                    return
                }

                switch amountType {
                case .coin, .reserve:
                    if let transactionInfo = extractTransactionInfo(
                        from: transaction,
                        sourceAddress: sourceAddress,
                        destinationAddress: destinationAddress,
                        walletAddress: walletAddress
                    ) {
                        partialResult += mapToTransactionRecords(
                            transaction: transaction,
                            transactionInfos: [transactionInfo],
                            fees: fees
                        )
                    }
                case .token(let token):
                    if let transfers = transaction.tokenTransfers, !transfers.isEmpty {
                        let outgoingTransactionInfos = extractTransactionInfos(
                            from: transfers,
                            token: token,
                            walletAddress: walletAddress,
                            isOutgoing: true
                        )
                        let incomingTransactionInfos = extractTransactionInfos(
                            from: transfers,
                            token: token,
                            walletAddress: walletAddress,
                            isOutgoing: false
                        )
                        partialResult += mapToTransactionRecords(
                            transaction: transaction,
                            transactionInfos: outgoingTransactionInfos + incomingTransactionInfos,
                            fees: fees
                        )
                    }
                }
            }
    }
}
