//
//  UTXOTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.08.2023.
//

import Foundation

struct UTXOTransactionHistoryMapper {
    private let blockchain: Blockchain
    private var decimalValue: Decimal {
        blockchain.decimalValue
    }
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

// MARK: - TransactionHistoryMapper

extension UTXOTransactionHistoryMapper: TransactionHistoryMapper {
    
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
                isOutgoing: isOutgoing,
                type: .transfer,
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
