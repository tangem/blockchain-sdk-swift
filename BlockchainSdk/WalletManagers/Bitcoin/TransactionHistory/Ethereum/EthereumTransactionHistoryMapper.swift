//
//  EthereumTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// ETH -> ETH Transfer
/// Contract -> Contract
/// ETH -> Contract -> Contract add token = SWAP to token
/// Contract -> ETH = SWAP to coin
/// Contract -> Contract = SWAP token to token

struct EthereumTransactionHistoryMapper {
    private let blockchain: Blockchain
    private let contract: String?
    
    private var decimalValue: Decimal {
        blockchain.decimalValue
    }
    
    init(blockchain: Blockchain, contract: String?) {
        self.blockchain = blockchain
        self.contract = contract
    }
}

// MARK: - TransactionHistoryMapper

extension EthereumTransactionHistoryMapper: TransactionHistoryMapper {
    
    func mapToTransactionRecords(_ response: BlockBookAddressResponse) -> [TransactionRecord] {
        if response.transactions.isEmpty {
            return []
        }
        
        return response.transactions.compactMap { transaction -> TransactionRecord? in
            guard let feeWei = Decimal(transaction.fees),
                  let source = source(transaction, walletAddress: response.address),
                  let destination = destination(transaction, walletAddress: response.address) else {
                assertionFailure("BlockBookAddressResponse.Transaction doesn't contain a required information")
                return nil
            }

            let status: TransactionStatus = transaction.confirmations > 0 ? .confirmed : .unconfirmed
            let fee = Fee(Amount(with: blockchain, value: feeWei / decimalValue))
            
            return TransactionRecord(
                hash: transaction.txid,
                source: .single(source),
                destination: .single(destination),
                fee: fee,
                status: status,
                isOutgoing: isOutgoing(transaction, walletAddress: response.address),
                type: transactionType(transaction),
                date: Date(timeIntervalSince1970: TimeInterval(transaction.blockTime)),
                tokenTransfers: tokenTransfers(transaction)
            )
        }
    }
    
    func isOutgoing(_ transaction: BlockBookAddressResponse.Transaction, walletAddress: String) -> Bool {
        switch contract {
        case .none:
            return transaction.vin.first?.addresses.first == walletAddress
        case .some(let contract):
            let transfer = transaction.tokenTransfers?.first(where: { insensitiveCompare(lhs: contract, rhs: $0.contract) })
            return transfer?.from == walletAddress
        }
    }
    
    func source(_ transaction: BlockBookAddressResponse.Transaction, walletAddress: String) -> TransactionRecord.Source? {
        guard let vin = transaction.vin.first, let address = vin.addresses.first else {
            print("Source information not found")
            return nil
        }
        
        switch contract {
        case .none:
            if let amount = Decimal(string: transaction.value) {
                return TransactionRecord.Source(address: address, amount: amount / decimalValue)
            }
        case .some(let contract):
            let tokenTransfers = transaction.tokenTransfers ?? []
            let transfer = tokenTransfers.first(where: { insensitiveCompare(lhs: contract, rhs: $0.contract) })

            if let transfer, let amount = Decimal(string: transfer.value) {
                let decimalValue = pow(10, transfer.decimals)
                return TransactionRecord.Source(address: address, amount: amount / decimalValue)
            }
        }
        
        return nil
    }
    
    func destination(_ transaction: BlockBookAddressResponse.Transaction, walletAddress: String) -> TransactionRecord.Destination? {
        guard let vout = transaction.vout.first, let address = vout.addresses.first else {
            print("Destination information not found")
            return nil
        }

        switch contract {
        case .none:
            if let amount = Decimal(string: transaction.value) {
                return TransactionRecord.Destination(address: .user(address), amount: amount / decimalValue)
            }
        case .some(let contract):
            let tokenTransfers = transaction.tokenTransfers ?? []
            let transfer = tokenTransfers.last(where: { insensitiveCompare(lhs: contract, rhs: $0.contract) })

            if let transfer, let amount = Decimal(string: transfer.value) {
                let decimalValue = pow(10, transfer.decimals)
                return TransactionRecord.Destination(address: .contract(address), amount: amount / decimalValue)
            }
        }
        
        return nil
    }
    
    func transactionType(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionType {
        guard let ethereumSpecific = transaction.ethereumSpecific else {
            return .transfer
        }
        
        let parsedData = ethereumSpecific.parsedData
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
    
    func insensitiveCompare(lhs: String, rhs: String) -> Bool {
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
