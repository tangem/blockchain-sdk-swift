//
//  BitcoinTransactionHistoryMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinTransactionHistoryMapper {
    let blockchain: Blockchain
    var decimalValue: Decimal {
        blockchain.decimalValue
    }
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func mapToTransactionRecords(_ response: BlockBookAddressResponse) -> [TransactionRecord] {
        let transactions = response.transactions ?? []
        
        guard !transactions.isEmpty else {
            return []
        }
        
        return transactions.compactMap { transaction -> TransactionRecord? in
            guard let feeSatoshi = Decimal(transaction.fees) else {
                return nil
            }
            
            let isOutgoing = transaction.vin.contains(where: { $0.isOwn == true })
            let amountSatoshi = transaction.vin.compactMap { Decimal($0.value ?? "") }.reduce(0, +)
            let status: TransactionStatus = transaction.confirmations > 0 ? .confirmed : .unconfirmed
            
            let fee = feeSatoshi / decimalValue
            let amount = amountSatoshi / decimalValue
            
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
                
                let amount = Amount(with: blockchain, value: amountSatoshi / decimalValue)
                return result + [TransactionRecord.Source(address: address, amount: amount)]
            }
            
            if spenders.count == 1, let spender = spenders.first {
                return .single(spender)
            }
            
            return .multiple(spenders)
        }
        
        func destinationType(vout: [BlockBookAddressResponse.Vout]) -> TransactionRecord.DestinationType {
            let destinations: [TransactionRecord.Destination] = vout.reduce([]) { result, output in
                // Skip the change to wallet address
                // The value isOwn will be in the response only if it's true
                if output.isOwn == true {
                    return result
                }
                
                guard let amountSatoshi = Decimal(output.value), let address = output.addresses.first else {
                    return result
                }
                
                let amount = Amount(with: blockchain, value: amountSatoshi / decimalValue)
                return result + [TransactionRecord.Destination(address: .user(address), amount: amount)]
            }
            
            if destinations.count == 1, let destination = destinations.first {
                return .single(destination)
            }
            
            return .multiple(destinations)
        }
    }
}
