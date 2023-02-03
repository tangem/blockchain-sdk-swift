//
//  TronTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 26.04.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftProtobuf
import web3swift
import WalletCore

class TronTransactionBuilder {
    private let blockchain: Blockchain
    // Taken from 50 USDT transactions, average is 88TRX, median is 15TRX, keep it on the safe side
    private let smartContractFeeLimit: Int64 = 40_000_000
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func input(amount: Amount, source: String, destination: String, block: TronBlock) throws -> TronSigningInput {
//        let contract = TronTransferContract.with {
//            $0.ownerAddress = source
//            $0.toAddress = destination
//            $0.amount = 1
//        }
        
//        contract(amount: amount, source: <#T##String#>, destination: <#T##String#>)
        
        print("Contract 1")
        print(try contract(amount: amount, source: source, destination: destination))
        print(try contract(amount: amount, source: source, destination: destination).jsonString())
        
        print("Contract 2")
        print(try contract2(amount: amount, source: source, destination: destination))
        
        
        
        let dummyPrivateKeyData = Data(repeating: 7, count: 32)
        let expirationInterval: Int64 = 10 * 60 * 60 * 1000
        let contract = try self.contract2(amount: amount, source: source, destination: destination)
        
        let input = TronSigningInput.with {
            $0.transaction = TronTransaction.with {
                $0.contractOneof = contract
                $0.timestamp = block.block_header.raw_data.timestamp
                $0.blockHeader = TronBlockHeader.with {
                    $0.timestamp = block.block_header.raw_data.timestamp
                    $0.number = block.block_header.raw_data.number
                    $0.version = block.block_header.raw_data.version
                    $0.txTrieRoot = Data(hexString: block.block_header.raw_data.txTrieRoot)
                    $0.parentHash = Data(hexString: block.block_header.raw_data.parentHash)
                    $0.witnessAddress = Data(hexString: block.block_header.raw_data.witness_address)
                }
                $0.expiration = block.block_header.raw_data.timestamp + expirationInterval
            }
            $0.privateKey = dummyPrivateKeyData
        }
        
        print(try! input.jsonString())
        return input
    }
    
    func transaction(amount: Amount, source: String, destination: String, input: TronSigningInput, output: TronSigningOutput) -> Data {
        let protocolTransaction = Protocol_Transaction.with {
            $0.rawData = Protocol_Transaction.raw.with {
                $0.refBlockHash = output.refBlockHash
                $0.refBlockBytes = output.refBlockBytes
                $0.timestamp = input.transaction.timestamp
                $0.expiration = input.transaction.expiration
                $0.contract = [
                    try! Protocol_Transaction.Contract.with {
                        let parameter = Protocol_TransferContract.with {
                            $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
                            $0.toAddress = TronAddressService.toByteForm(destination) ?? Data()
                            $0.amount = self.integerValue(from: amount).int64Value
                        }
                        
                        $0.type = .transferContract
                        $0.parameter = try Google_Protobuf_Any(message: parameter)
                    }
                 ]
                }
//            $0.signature = [unmarshalledSignature]
            $0.signature = [output.signature]
        }
        
        return try! protocolTransaction.serializedData()
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
            
            let addressData = TronAddressService.toByteForm(destination)?.padLeft(length: 32) ?? Data()
            
            guard
                let bigIntValue = Web3.Utils.parseToBigUInt("\(amount.value)", decimals: token.decimalCount)
            else {
                throw WalletError.failedToBuildTx
            }
            
            let amountData = bigIntValue.serialize().padLeft(length: 32)
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
    
    private func contract2(amount: Amount, source: String, destination: String) throws -> TW_Tron_Proto_Transaction.OneOf_ContractOneof {
        switch amount.type {
        case .coin:
//            let parameter = Protocol_TransferContract.with {
            let parameter = TronTransferContract.with {
                $0.ownerAddress = source //TronAddressService.toByteForm(source) ?? Data()
                $0.toAddress = destination //TronAddressService.toByteForm(destination) ?? Data()
                $0.amount = integerValue(from: amount).int64Value
            }
            
            return .transfer(parameter)
            
//            return .transfer(<#T##TW_Tron_Proto_TransferContract#>)
//            return try Protocol_Transaction.Contract.with {
//                $0.type = .transferContract
//                $0.parameter = try Google_Protobuf_Any(message: parameter)
//            }
        case .token(let token):
            let functionSelector = "transfer(address,uint256)"
            let functionSelectorHash = Data(functionSelector.bytes).sha3(.keccak256).prefix(4)

            let addressData = TronAddressService.toByteForm(destination)?.padLeft(length: 32) ?? Data()
//
            guard
                let bigIntValue = Web3.Utils.parseToBigUInt("\(amount.value)", decimals: token.decimalCount)
            else {
                throw WalletError.failedToBuildTx
            }
//
            let amountData = bigIntValue.serialize().padLeft(length: 32)
            let contractData = functionSelectorHash + addressData + amountData
//
//            let parameter = Protocol_TriggerSmartContract.with {
//                $0.contractAddress = TronAddressService.toByteForm(token.contractAddress) ?? Data()
//                $0.data = contractData
//                $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
//            }
            
//            return try Protocol_Transaction.Contract.with {
//                $0.type = .triggerSmartContract
//                $0.parameter = try Google_Protobuf_Any(message: parameter)
//            }
            
            let parameter = TronTriggerSmartContract.with {
                $0.contractAddress = "QXAIIkN4Tc3zBCA057BE1tNCqRNg" //token.contractAddress
                $0.ownerAddress = "QTd9v0V5paURNNR81VM3jWrv6Bd5" //source
//                $0.toAddress = destination
//                $0.amount = amountData
                
                
//                $0.ownerAddress =
//                $0.contractAddress =
//                $0.callValue =
                $0.data = contractData
//                $0.callTokenValue =
//                $0.tokenID =

            }
            
            
//            let parameter = TronTriggerSmartContract.with {
//                $0.contractAddress = token.contractAddress
//                $0.ownerAddress = source
//                $0.toAddress = destination
//                $0.amount = amountData
//            }
//            return .transferTrc20Contract(parameter)
            
            return .triggerSmartContract(parameter)
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

fileprivate extension Data {
    func padLeft(length: Int) -> Data {
        let extraLength = Swift.max(0, length - self.count)
        return Data(repeating: 0, count: extraLength) + self
    }
}
