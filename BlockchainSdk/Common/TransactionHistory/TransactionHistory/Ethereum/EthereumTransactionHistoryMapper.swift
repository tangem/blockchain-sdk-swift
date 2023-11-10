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
            guard let source = source(transaction, walletAddress: response.address, amountType: amountType),
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
            let transfer = transaction.tokenTransfers?.first(where: { transfer in
                guard let contract = transfer.contract else { 
                    return false
                }

                return isCaseInsensitiveMatch(lhs: token.contractAddress, rhs: contract)
            })
            return transfer?.from == walletAddress
        }
    }
    
    func source(_ transaction: BlockBookAddressResponse.Transaction,  walletAddress: String, amountType: Amount.AmountType) -> TransactionRecord.Source? {
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
            let transfers = tokenTransfers.filter { transfer in
                guard let contract = transfer.contract else {
                    return false
                }
                
                return isCaseInsensitiveMatch(lhs: token.contractAddress, rhs: contract)
            }
            
            let transfer: BlockBookAddressResponse.TokenTransfer? = {
                if transfers.count == 1, let first = transfers.first {
                    return first
                }
                
                return transfers.first { isCaseInsensitiveMatch(lhs: $0.from, rhs: walletAddress) }
            }()
            
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
                let isContract = !tokenTransfers.isEmpty
                return TransactionRecord.Destination(address: isContract ? .contract(address) : .user(address), amount: amount / decimalValue)
            }
        case .token(let token):
            let transfers = tokenTransfers.filter { transfer in
                guard let contract = transfer.contract else {
                    return false
                }
                
                return isCaseInsensitiveMatch(lhs: token.contractAddress, rhs: contract)
            }
            
            let transfer: BlockBookAddressResponse.TokenTransfer? = {
                if transfers.count == 1, let first = transfers.first {
                    return first
                }
                
                return transfers.first { isCaseInsensitiveMatch(lhs: $0.to, rhs: walletAddress) }
            }()

            if let transfer, let amount = Decimal(transfer.value) {
                let decimalValue = pow(10, transfer.decimals)
                let isOutgoing = transfer.from == walletAddress
                return TransactionRecord.Destination(address: isOutgoing ? .user(transfer.to) : .user(transfer.from), amount: amount / decimalValue)
            }
        }
        
        return nil
    }
    
    func transactionType(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionType {
        guard let methodId = transaction.ethereumSpecific?.parsedData?.methodId else {
            return .transfer
        }
        
        // MethodId is empty for the coin transfers
        if methodId.isEmpty {
            return .transfer
        }
        
        return .contractMethod(id: methodId)
    }
    
    func tokenTransfers(_ transaction: BlockBookAddressResponse.Transaction) -> [TransactionRecord.TokenTransfer]? {
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
                contract: transfer.contract
            )
        }
    }
    
    func isCaseInsensitiveMatch(lhs: String, rhs: String) -> Bool {
        return lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }
}
