//
//  TronTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 26.04.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftProtobuf
import CryptoSwift

class TronTransactionBuilder {
    private let blockchain: Blockchain
    private let smartContractFeeLimit: Int64 = 100_000_000
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func buildForSign(amount: Amount, source: String, destination: String, block: TronBlock) throws -> Protocol_Transaction.raw {
        let contract = try self.contract(amount: amount, source: source, destination: destination)
        let feeLimit = (amount.type == .coin) ? 0 : smartContractFeeLimit
        
        let blockHeaderRawData = block.block_header.raw_data
        let blockHeader = Protocol_BlockHeader.raw.with {
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
        
        let rawData = Protocol_Transaction.raw.with {
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
    
    func buildForSend(rawData: Protocol_Transaction.raw, signature: Data) -> Protocol_Transaction {
        let transaction = Protocol_Transaction.with {
            $0.rawData = rawData
            $0.signature = [signature]
        }
        return transaction
    }
    
    private func contract(amount: Amount, source: String, destination: String) throws -> Protocol_Transaction.Contract {
        switch amount.type {
        case .coin:
            let parameter = Protocol_TransferContract.with {
                $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
                $0.toAddress = TronAddressService.toByteForm(destination) ?? Data()
                $0.amount = integerValue(from: amount).int64Value
            }
            
            return try Protocol_Transaction.Contract.with {
                $0.type = .transferContract
                $0.parameter = try Google_Protobuf_Any(message: parameter)
            }
        case .token(let token):
            let functionSelector = "transfer(address,uint256)"
            let functionSelectorHash = Data(functionSelector.bytes).sha3(.keccak256).prefix(4)
            
            let addressData = TronAddressService.toByteForm(destination)?.aligned(to: 32) ?? Data()
            
            guard
                let bigIntValue = EthereumUtils.parseToBigUInt("\(amount.value)", decimals: token.decimalCount)
            else {
                throw WalletError.failedToBuildTx
            }
            
            let amountData = bigIntValue.serialize().aligned(to: 32)
            let contractData = functionSelectorHash + addressData + amountData
            
            let parameter = Protocol_TriggerSmartContract.with {
                $0.contractAddress = TronAddressService.toByteForm(token.contractAddress) ?? Data()
                $0.data = contractData
                $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
            }
            
            return try Protocol_Transaction.Contract.with {
                $0.type = .triggerSmartContract
                $0.parameter = try Google_Protobuf_Any(message: parameter)
            }
        case .reserve:
            fatalError()
        }
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
