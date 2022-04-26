//
//  TronTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 26.04.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftProtobuf
import BinanceChain

class TronTransactionBuilder {
    private let blockchain: Blockchain
    private let feeLimit: Int64 = 10_000_000
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func buildForSign(amount: Amount, source: String, destination: String, block: TronBlock) -> Protocol_Transaction.raw {
        let intAmount = uint64(from: amount)
        
        let contract: Protocol_Transaction.Contract
        switch amount.type {
        case .coin:
            let parameter = Protocol_TransferContract.with {
                $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
                $0.toAddress = TronAddressService.toByteForm(destination) ?? Data()
                $0.amount = intAmount
            }
            
            contract = Protocol_Transaction.Contract.with {
                $0.type = .transferContract
                $0.parameter = try! Google_Protobuf_Any(message: parameter)
            }
        case .token(let token):
            let functionSelector = "transfer(address,uint256)"
            let functionSelectorHash = Data(functionSelector.bytes).sha3(.keccak256).prefix(4)
            
            let hexAddress = TronAddressService.toByteForm(destination)?.padLeft(length: 32) ?? Data()
            let hexAmount = Data(Data(from: intAmount).reversed()).padLeft(length: 32)
            let contractData = functionSelectorHash + hexAddress + hexAmount
            
            let parameter = Protocol_TriggerSmartContract.with {
                $0.contractAddress = TronAddressService.toByteForm(token.contractAddress)!
                $0.data = contractData
                $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
            }

            contract = Protocol_Transaction.Contract.with {
                $0.type = .triggerSmartContract
                $0.parameter = try! Google_Protobuf_Any(message: parameter)
            }
        case .reserve:
            fatalError()
        }
        
        let blockHeader = Protocol_BlockHeader.raw.with {
            $0.timestamp = block.block_header.raw_data.timestamp
            $0.number = block.block_header.raw_data.number
            $0.version = block.block_header.raw_data.version
            $0.txTrieRoot = Data(hex: block.block_header.raw_data.txTrieRoot)
            $0.parentHash = Data(hex: block.block_header.raw_data.parentHash)
            $0.witnessAddress = Data(hex: block.block_header.raw_data.witness_address)
        }
        
        let blockData = try! blockHeader.serializedData()
        let blockHash = blockData.getSha256()
        let refBlockHash = blockHash[8..<16]
        print(blockData.hex)
        print(blockData.getSha256().hexString)
        print(refBlockHash.hexString)
        
        let number = blockHeader.number
        let numberData = Data(Data(from: number).reversed())
        let refBlockBytes = numberData[6..<8]
        
        print(Data(numberData.reversed()).hex)
        print(refBlockBytes.hex)
        
        let tenHours: Int64 = 10 * 60 * 60 * 1000
        
        let rawData = Protocol_Transaction.raw.with {
            $0.timestamp = blockHeader.timestamp
            $0.expiration = blockHeader.timestamp + tenHours
            $0.refBlockHash = refBlockHash//Data(hex: "349a4a4774130149")
            $0.refBlockBytes = refBlockBytes//Data(hex: "bf1f")
            $0.contract = [
                contract
            ]
            $0.feeLimit = feeLimit
        }
        
        
//        let transaction = Protocol_Transaction.with {
//            $0.rawData = rawData
//            $0.signature = [Data(repeating: 0, count: 65)]
//        }
        return rawData
    }
    
    func buildForSend(rawData: Protocol_Transaction.raw, signature: Data) -> Protocol_Transaction {
        let transaction = Protocol_Transaction.with {
            $0.rawData = rawData
            $0.signature = [signature]
        }
        return transaction
    }
    
    
    private func uint64(from amount: Amount) -> Int64 {
        let decimalValue: Decimal
        switch amount.type {
        case .coin:
            decimalValue = blockchain.decimalValue
        case .token(let token):
            decimalValue = token.decimalValue
        case .reserve:
            fatalError()
        }
        
        let decimalAmount = amount.value * decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).int64Value
        return intAmount
    }
}


fileprivate extension Data {
    func padLeft(length: Int) -> Data {
        let extraLength = Swift.max(0, length - self.count)
        return Data(repeating: 0, count: extraLength) + self
    }
}
