//
//  EthereumTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct EthereumTransactionHistoryMapper {
    private let blockchain: Blockchain
    
    private var decimalValue: Decimal {
        blockchain.decimalValue
    }
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

// MARK: - BlockBookTransactionHistoryMapper

extension EthereumTransactionHistoryMapper: BlockBookTransactionHistoryMapper {
    func mapToTransactionRecords(_ response: BlockBookAddressResponse, amountType: Amount.AmountType) -> [TransactionRecord] {
        guard let transactions = response.transactions else {
            return []
        }
        
        return transactions.compactMap { transaction -> TransactionRecord? in
            guard let source = source(transaction, amountType: amountType),
                  let destination = destination(transaction, walletAddress: response.address, amountType: amountType),
                  let feeWei = Decimal(transaction.fees) else {
                Log.debug("BlockBookAddressResponse.Transaction \(transaction) doesn't contain a required information")
                return nil
            }
            
            let fee = Fee(Amount(with: blockchain, value: feeWei / decimalValue))
            
            return TransactionRecord(
                hash: transaction.txid,
                source: .single(source),
                destination: .single(destination),
                fee: fee,
                status: status(transaction),
                isOutgoing: isOutgoing(transaction, walletAddress: response.address, amountType: amountType),
                type: transactionType(transaction),
                date: Date(timeIntervalSince1970: TimeInterval(transaction.blockTime)),
                tokenTransfers: tokenTransfers(transaction)
            )
        }
    }
}

// MARK: - Private

private extension EthereumTransactionHistoryMapper {
    func status(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionStatus {
        guard let status = transaction.ethereumSpecific?.status else {
            return transaction.confirmations > 0 ? .confirmed : .unconfirmed
        }
        
        switch status {
        case .failure:
            return .failed
        case .ok:
            return .confirmed
        case .pending:
            return .unconfirmed
        }
    }
    
    func isOutgoing(_ transaction: BlockBookAddressResponse.Transaction, walletAddress: String, amountType: Amount.AmountType) -> Bool {
        switch amountType {
        case .coin, .reserve:
            return transaction.vin.first?.addresses.first == walletAddress
        case .token(let token):
            let transfer = transaction.tokenTransfers?.first(where: { isCaseInsensitiveMatch(lhs: token.contractAddress, rhs: $0.contract) })
            return transfer?.from == walletAddress
        }
    }
    
    func source(_ transaction: BlockBookAddressResponse.Transaction, amountType: Amount.AmountType) -> TransactionRecord.Source? {
        guard let vin = transaction.vin.first, let address = vin.addresses.first else {
            Log.debug("Source information in transaction \(transaction) not found")
            return nil
        }
        
        switch amountType {
        case .coin, .reserve:
            if let amount = Decimal(string: transaction.value) {
                return TransactionRecord.Source(address: address, amount: amount / decimalValue)
            }
        case .token(let token):
            let tokenTransfers = transaction.tokenTransfers ?? []
            let transfer = tokenTransfers.first(where: { isCaseInsensitiveMatch(lhs: token.contractAddress, rhs: $0.contract) })
            
            if let transfer, let amount = Decimal(transfer.value) {
                let decimalValue = pow(10, transfer.decimals)
                return TransactionRecord.Source(address: address, amount: amount / decimalValue)
            }
        }
        
        return nil
    }
    
    func destination(_ transaction: BlockBookAddressResponse.Transaction, walletAddress: String, amountType: Amount.AmountType) -> TransactionRecord.Destination? {
        guard let vout = transaction.vout.first, let address = vout.addresses.first else {
            Log.debug("Destination information in transaction \(transaction) not found")
            return nil
        }
        
        let tokenTransfers = transaction.tokenTransfers ?? []
        
        switch amountType {
        case .coin, .reserve:
            if let amount = Decimal(string: transaction.value) {
                let isContact = !tokenTransfers.isEmpty
                return TransactionRecord.Destination(address: isContact ? .contract(address) : .user(address), amount: amount / decimalValue)
            }
        case .token(let token):
            let transfer = tokenTransfers.last(where: { isCaseInsensitiveMatch(lhs: token.contractAddress, rhs: $0.contract) })

            if let transfer, let amount = Decimal(transfer.value) {
                let decimalValue = pow(10, transfer.decimals)
                let isOutgoing = transfer.from == walletAddress
                return TransactionRecord.Destination(address: isOutgoing ? .user(transfer.to) : .user(transfer.from), amount: amount / decimalValue)
            }
        }
        
        return nil
    }
    
    func transactionType(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionType {
        guard let parsedData = transaction.ethereumSpecific?.parsedData else {
            return .transfer
        }
        
        if parsedData.methodId.isEmpty {
            return .transfer
        }
        
        return TransactionRecord.TransactionType.from(hex: parsedData.methodId)
    }
    
    func tokenTransfers(_ transaction: BlockBookAddressResponse.Transaction) -> [TransactionRecord.TokenTransfer]? {
        guard let tokenTransfers = transaction.tokenTransfers else {
            return nil
        }
        
        return tokenTransfers.compactMap { transfer -> TransactionRecord.TokenTransfer? in
            guard let amount = Decimal(transfer.value) else {
                return nil
            }
            
            return TransactionRecord.TokenTransfer(
                source: transfer.from,
                destination: transfer.to,
                amount: amount,
                name: transfer.name,
                symbol: transfer.symbol,
                decimals: transfer.decimals,
                contract: transfer.contract
            )
        }
    }
    
    func isCaseInsensitiveMatch(lhs: String, rhs: String) -> Bool {
        return lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }
}

public extension TransactionRecord.TransactionType {
    static func from(hex: String) -> Self {
        if let method = TransactionRecord.TransactionType.data.first(where: { $0.value.contains(hex) })?.key {
            return method
        }
        
        return .custom(id: hex)
    }
    
    static let data: [TransactionRecord.TransactionType: [String]] = [
        .transfer: ["0xa9059cbb"],
        .submit: ["0xa1903eab"],
        .approve: ["0x095ea7b3"],
        .supply: ["0x617ba037"],
        .withdraw: ["0x69328dec"],
        .deposit: ["0xe8eda9df"],
        .swap: ["0x12aa3caf"],
        .unoswap: ["0x0502b1c5", "0x2e95b6c8"],
    ]
}
