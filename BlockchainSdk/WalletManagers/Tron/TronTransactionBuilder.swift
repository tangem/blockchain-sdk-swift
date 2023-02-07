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
        let dummyPrivateKeyData = Data(repeating: 7, count: 32)
        let expirationInterval: Int64 = 10 * 60 * 60 * 1000
        let contract = try self.contract(amount: amount, source: source, destination: destination)
        let feeLimit = (amount.type == .coin) ? 0 : smartContractFeeLimit
        
        let input = TronSigningInput.with {
            $0.transaction = TronTransaction.with {
                $0.contractOneof = contract
                $0.timestamp = block.block_header.raw_data.timestamp
                $0.expiration = block.block_header.raw_data.timestamp + expirationInterval
                $0.feeLimit = feeLimit
                $0.blockHeader = TronBlockHeader.with {
                    $0.timestamp = block.block_header.raw_data.timestamp
                    $0.number = block.block_header.raw_data.number
                    $0.version = block.block_header.raw_data.version
                    $0.txTrieRoot = Data(hexString: block.block_header.raw_data.txTrieRoot)
                    $0.parentHash = Data(hexString: block.block_header.raw_data.parentHash)
                    $0.witnessAddress = Data(hexString: block.block_header.raw_data.witness_address)
                }
            }
            $0.privateKey = dummyPrivateKeyData
        }
        
        return input
    }
    
    func transaction(amount: Amount, source: String, destination: String, input: TronSigningInput, output: TronSigningOutput) throws -> Data {
        guard let contract = try input.transaction.contractOneof?.toProtocolContract() else {
            throw WalletError.failedToBuildTx
        }
        
        let protocolTransaction = Protocol_Transaction.with {
            $0.rawData = Protocol_Transaction.raw.with {
                $0.refBlockHash = output.refBlockHash
                $0.refBlockBytes = output.refBlockBytes
                $0.timestamp = input.transaction.timestamp
                $0.expiration = input.transaction.expiration
                $0.feeLimit = input.transaction.feeLimit
                $0.contract = [contract]
            }
            
            $0.signature = [output.signature]
        }
        
        return try protocolTransaction.serializedData()
    }
    
    private func contract(amount: Amount, source: String, destination: String) throws -> TW_Tron_Proto_Transaction.OneOf_ContractOneof {
        switch amount.type {
        case .coin:
            let parameter = TronTransferContract.with {
                $0.ownerAddress = source
                $0.toAddress = destination
                $0.amount = integerValue(from: amount).int64Value
            }
            
            return .transfer(parameter)
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
            
            let parameter = TronTriggerSmartContract.with {
                $0.contractAddress = token.contractAddress
                $0.ownerAddress = source
                $0.data = contractData
            }
            
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

fileprivate extension TW_Tron_Proto_Transaction.OneOf_ContractOneof {
    func toProtocolContract() throws -> Protocol_Transaction.Contract {
        switch self {
        case .transfer(let trustWalletParameters):
            let message = Protocol_TransferContract.with {
                $0.ownerAddress = TronAddressService.toByteForm(trustWalletParameters.ownerAddress) ?? Data()
                $0.toAddress = TronAddressService.toByteForm(trustWalletParameters.toAddress) ?? Data()
                $0.amount = trustWalletParameters.amount
            }
            
            return try Protocol_Transaction.Contract.with {
                $0.type = .transferContract
                $0.parameter = try Google_Protobuf_Any(message: message)
            }
        case .triggerSmartContract(let trustWalletParameters):
            let message = Protocol_TriggerSmartContract.with {
                $0.contractAddress = TronAddressService.toByteForm(trustWalletParameters.contractAddress) ?? Data()
                $0.ownerAddress = TronAddressService.toByteForm(trustWalletParameters.ownerAddress) ?? Data()
                $0.data = trustWalletParameters.data
            }
            
            return try Protocol_Transaction.Contract.with {
                $0.type = .triggerSmartContract
                $0.parameter = try Google_Protobuf_Any(message: message)
            }
        default:
            throw WalletError.failedToBuildTx
        }
    }
}
