//
//  TransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct EthereumTransactionHistoryMapper {
    let blockchain: Blockchain
    var decimalValue: Decimal {
        blockchain.decimalValue
    }
    
    init(blockchain: Blockchain, abiEncoder: WalletCoreABIEncoder) {
        self.blockchain = blockchain
    }
    
    func mapToTransactionRecords(_ response: BlockBookAddressResponse) -> [TransactionRecord] {
        let transactions = response.transactions ?? []
        
        guard !transactions.isEmpty else {
            return []
        }
        
        return transactions.compactMap { transaction -> TransactionRecord? in
            guard let feeWei = Decimal(transaction.fees),
                  let ethereumSpecific = transaction.ethereumSpecific,
                  let source = sourceType(transaction),
                  let destination = destinationType(transaction),
                  let type = transactionType(transaction) else {
                return nil
            }
            
            let status: TransactionStatus = transaction.confirmations > 0 ? .confirmed : .unconfirmed
            let fee = Fee(Amount(with: blockchain, value: feeWei / decimalValue))
            
            return TransactionRecord(
                hash: transaction.txid,
                source: source,
                destination: destination,
                fee: fee,
                status: status,
                type: type,
                date: Date(timeIntervalSince1970: TimeInterval(transaction.blockTime)),
                tokenTransfers: tokenTransfers(transaction)
            )
        }
    }
    
    func sourceType(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.SourceType? {
        guard let vin = transaction.vin.first,
              let address = vin.addresses.first,
              let amount = Decimal(transaction.value) else {
            print("Source information not found")
            return nil
        }

        let source = TransactionRecord.Source(address: address, amount: amount)
        return .single(source)
    }
    
    func destinationType(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.DestinationType? {
        guard let vout = transaction.vout.first, let destination = vout.addresses.first, let amount = Decimal(vout.value) else {
            print("Destination information not found")
            return nil
        }
        
        let isContract = transaction.tokenTransfers?.contains(where: { $0.contract == destination }) ?? false
        let address: TransactionRecord.Destination.Address = isContract ? .contract(destination) : .user(destination)
        let source = TransactionRecord.Destination(address: address, amount: amount / decimalValue)

        return .single(source)
    }
    
    func transactionType(_ transaction: BlockBookAddressResponse.Transaction) -> TransactionRecord.TransactionType? {
        guard let ethereumSpecific = transaction.ethereumSpecific  else {
            return nil
        }
        
        let isOutgoing = transaction.vin.first?.isOwn == true
        let parsedData = ethereumSpecific.parsedData
        
        switch parsedData.name {
        case "Transfer":
            return isOutgoing ? .send : .receive
        default:
            return .ethereumMethod(parsedData.methodId) // TODO: add decoding
        }
        
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
}

struct TransactionHistoryMapper {
    private let blockchain: Blockchain
    private var decimalValue: Decimal {
        blockchain.decimalValue
    }
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func mapToTransactionRecords(_ response: BlockBookAddressResponse) -> [TransactionRecord] {
        let transactions = response.transactions ?? []
        
        if transactions.isEmpty {
            return []
        }
        
        return transactions.compactMap { transaction -> TransactionRecord? in
            guard let feeSatoshi = Decimal(transaction.fees) else {
                return nil
            }
            
            let isOutgoing = transaction.vin.contains(where: { $0.isOwn == true })
            let status: TransactionStatus = transaction.confirmations > 0 ? .confirmed : .unconfirmed
            let fee = feeSatoshi / decimalValue
            
            return TransactionRecord(
                hash: transaction.txid,
                source: sourceType(vin: transaction.vin),
                destination: destinationType(vout: transaction.vout),
                fee: Fee(Amount(with: blockchain, value: fee)),
                status: status,
                type: isOutgoing ? .send : .receive,
                date: Date(timeIntervalSince1970: TimeInterval(transaction.blockTime))
            )
        }
        
        func sourceType(vin: [BlockBookAddressResponse.Vin]) -> TransactionRecord.SourceType {
            let spenders: [TransactionRecord.Source] = vin.reduce([]) { result, input in
                guard let value = input.value,
                      let amountSatoshi = Decimal(value),
                      let address = input.addresses.first else {
                    return result
                }
                
                let amount = amountSatoshi / decimalValue
                return result + [TransactionRecord.Source(address: address, amount: amount)]
            }
            
            if spenders.count == 1, let spender = spenders.first {
                return .single(spender)
            }
            
            return .multiple(spenders)
        }
        
        func destinationType(vout: [BlockBookAddressResponse.Vout]) -> TransactionRecord.DestinationType {
            let destinations: [TransactionRecord.Destination] = vout.reduce([]) { result, output in
                guard let amountSatoshi = Decimal(output.value),
                      let address = output.addresses.first else {
                    return result
                }
                
                let amount = amountSatoshi / decimalValue
                return result + [TransactionRecord.Destination(address: .user(address), amount: amount)]
            }
            
            if destinations.count == 1, let destination = destinations.first {
                return .single(destination)
            }
            
            return .multiple(destinations)
        }
    }
}
