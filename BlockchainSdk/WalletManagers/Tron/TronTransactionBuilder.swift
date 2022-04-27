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
    private let smartContractFeeLimit: Int64 = 10_000_000
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func buildForSign(amount: Amount, source: String, destination: String, block: TronBlock) throws -> Tron_Transaction.raw {
        let contract: Tron_Transaction.Contract
        let feeLimit: Int64
        
        switch amount.type {
        case .coin:
            let parameter = Tron_TransferContract.with {
                $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
                $0.toAddress = TronAddressService.toByteForm(destination) ?? Data()
                $0.amount = integerValue(from: amount).int64Value
            }
            
            contract = try Tron_Transaction.Contract.with {
                $0.type = .transferContract
                $0.parameter = try Google_Protobuf_Any(message: parameter)
            }
            
            feeLimit = 0
        case .token(let token):
            let functionSelector = "transfer(address,uint256)"
            let functionSelectorHash = Data(functionSelector.bytes).sha3(.keccak256).prefix(4)
            
            let hexAddress = TronAddressService.toByteForm(destination)?.padLeft(length: 32) ?? Data()
            
            let uintAmount = integerValue(from: amount).uint64Value
            let hexAmount = Data(Data(from: uintAmount).reversed()).padLeft(length: 32)
            
            let contractData = functionSelectorHash + hexAddress + hexAmount
            
            let parameter = Tron_TriggerSmartContract.with {
                $0.contractAddress = TronAddressService.toByteForm(token.contractAddress) ?? Data()
                $0.data = contractData
                $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
            }
            
            contract = try Tron_Transaction.Contract.with {
                $0.type = .triggerSmartContract
                $0.parameter = try Google_Protobuf_Any(message: parameter)
            }
            
            feeLimit = smartContractFeeLimit
        case .reserve:
            fatalError()
        }
        
        let blockHeaderRawData = block.block_header.raw_data
        let blockHeader = Tron_BlockHeader.raw.with {
            $0.timestamp = blockHeaderRawData.timestamp
            $0.number = blockHeaderRawData.number
            $0.version = blockHeaderRawData.version
            $0.txTrieRoot = Data(hex: blockHeaderRawData.txTrieRoot)
            $0.parentHash = Data(hex: blockHeaderRawData.parentHash)
            $0.witnessAddress = Data(hex: blockHeaderRawData.witness_address)
        }
        
        let blockData = try blockHeader.serializedData()
        let blockHash = blockData.getSha256()
        let refBlockHash = blockHash[8..<16]
        
        let number = blockHeader.number
        let numberData = Data(Data(from: number).reversed())
        let refBlockBytes = numberData[6..<8]
        
        let tenHours: Int64 = 10 * 60 * 60 * 1000 // same as WalletCore
        
        let rawData = Tron_Transaction.raw.with {
            $0.timestamp = blockHeader.timestamp
            $0.expiration = blockHeader.timestamp + tenHours
            $0.refBlockHash = refBlockHash
            $0.refBlockBytes = refBlockBytes
            $0.contract = [
                contract
            ]
            $0.feeLimit = feeLimit
        }
        
        return rawData
    }
    
    func buildForSend(rawData: Tron_Transaction.raw, signature: Data) -> Tron_Transaction {
        let transaction = Tron_Transaction.with {
            $0.rawData = rawData
            $0.signature = [signature]
        }
        return transaction
    }
    
    
    private func integerValue(from amount: Amount) -> NSDecimalNumber {
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
        return (decimalAmount.rounded() as NSDecimalNumber)
    }
}


fileprivate extension Data {
    func padLeft(length: Int) -> Data {
        let extraLength = Swift.max(0, length - self.count)
        return Data(repeating: 0, count: extraLength) + self
    }
}
