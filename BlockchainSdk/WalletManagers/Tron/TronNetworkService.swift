//
//  TronNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import web3swift
import SwiftProtobuf

class TronNetworkService {
    private let blockchain: Blockchain
    private let rpcProvider: TronJsonRpcProvider
    
    init(blockchain: Blockchain, rpcProvider: TronJsonRpcProvider) {
        self.blockchain = blockchain
        self.rpcProvider = rpcProvider
    }
    
    func accountInfo(for address: String, tokens: [Token], transactionIDs: [String]) -> AnyPublisher<TronAccountInfo, Error> {
        let blockchain = self.blockchain
        let tokenBalancePublishers = tokens.map { tokenBalance(address: address, token: $0) }
        let confirmedTransactionPublishers = transactionIDs.map { transactionConfirmed(id: $0) }
        
        return rpcProvider.getAccount(for: address)
            .zip(Publishers.MergeMany(tokenBalancePublishers).collect(),
                 rpcProvider.getNowBlock(),
            Publishers.MergeMany(confirmedTransactionPublishers).collect())
            .map { (accountInfo, tokenInfoList,b, confirmedTransactionList) in
                print(b)
                let balance = Decimal(accountInfo.balance) / blockchain.decimalValue
                let tokenBalances = Dictionary(uniqueKeysWithValues: tokenInfoList)
                let confirmedTransactionIDs = confirmedTransactionList.compactMap { $0 }
                
                return TronAccountInfo(balance: balance, tokenBalances: tokenBalances, confirmedTransactionIDs: confirmedTransactionIDs)
            }
            .eraseToAnyPublisher()
    }
    
    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        rpcProvider.getAccount(for: address)
    }
    
    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        rpcProvider.getNowBlock()
    }
    
    func createTransaction(from source: String, to destination: String, amount: Int64) -> AnyPublisher<Protocol_Transaction.raw, Error> {
//        rpcProvider.createTransaction(from: source, to: destination, amount: amount)
        rpcProvider.getNowBlock()
            .map { block -> Protocol_Transaction.raw in
                let contractParameter = Protocol_TransferContract.with {
                    $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
                    $0.toAddress = TronAddressService.toByteForm(destination) ?? Data()
                    $0.amount = amount
                }
                
                print(contractParameter.amount)
                
                let contract = Protocol_Transaction.Contract.with {
                    $0.type = .transferContract
                    $0.parameter = try! Google_Protobuf_Any(message: contractParameter)
                }

//                let blockHeader = Protocol_BlockHeader.raw.with {
//                    $0.timestamp = 1539295479000
//                    $0.number = 3111739
//                    $0.version = 3
//                    $0.txTrieRoot = Data(hexString: "64288c2db0641316762a99dbb02ef7c90f968b60f9f2e410835980614332f86d")
//                    $0.parentHash = Data(hexString: "00000000002f7b3af4f5f8b9e23a30c530f719f165b742e7358536b280eead2d")
//                    $0.witnessAddress = Data(hexString: "415863f6091b8e71766da808b1dd3159790f61de7d")
//                }
                
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
                }
                
                
                let transaction = Protocol_Transaction.with {
                    $0.rawData = rawData
                    $0.signature = [Data(repeating: 0, count: 65)]
                }
                return rawData
                do {
                    
                    let data = try transaction.serializedData()
                    let json = try transaction.jsonString()
                    print(data.count)
                    print(data.hex)
                    print(json)
                } catch {
                    print(error)
//                    return Data()
                }

            }
            .eraseToAnyPublisher()
    }
    
    func createTrc20Transaction(from source: String, to destination: String, contractAddress: String, amount: Int64) -> AnyPublisher<Protocol_Transaction.raw, Error> {
        rpcProvider.getNowBlock()
            .map { block -> Protocol_Transaction.raw in
                let TRANSFER_TOKEN_FUNCTION = "a9059cbb"//"70a08231"
                
                let hexAddress = TronAddressService.toHexForm(destination, length: 64) ?? ""
                let hexAmount = String(repeating: "0", count: 48) + Data(Data(from: amount).reversed()).hex
                let parameter = hexAddress + hexAmount
                
                let contractData = Data(hex: TRANSFER_TOKEN_FUNCTION + parameter)
                
                print(contractData.hex)
                
                let contractParameter = Protocol_TriggerSmartContract.with {
                    $0.contractAddress = TronAddressService.toByteForm(contractAddress)!
                    $0.data = contractData
                    
                    $0.ownerAddress = TronAddressService.toByteForm(source) ?? Data()
//                    $0.toAddress = TronAddressService.toByteForm(destination) ?? Data()
//                    $0.amount = amount
                }
                
//                print(contractParameter.amount)
                
                let contract = Protocol_Transaction.Contract.with {
                    $0.type = .transferContract
                    $0.parameter = try! Google_Protobuf_Any(message: contractParameter)
                }

//                let blockHeader = Protocol_BlockHeader.raw.with {
//                    $0.timestamp = 1539295479000
//                    $0.number = 3111739
//                    $0.version = 3
//                    $0.txTrieRoot = Data(hexString: "64288c2db0641316762a99dbb02ef7c90f968b60f9f2e410835980614332f86d")
//                    $0.parentHash = Data(hexString: "00000000002f7b3af4f5f8b9e23a30c530f719f165b742e7358536b280eead2d")
//                    $0.witnessAddress = Data(hexString: "415863f6091b8e71766da808b1dd3159790f61de7d")
//                }
                
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
                }
                
                
                let transaction = Protocol_Transaction.with {
                    $0.rawData = rawData
                    $0.signature = [Data(repeating: 0, count: 65)]
                }
                return rawData
            }
            .eraseToAnyPublisher()
    }
    
    func broadcastTransaction<T: Codable>(_ transaction: TronTransactionRequest<T>) -> AnyPublisher<TronBroadcastResponse, Error> {
        rpcProvider.broadcastTransaction(transaction)
    }
    
    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        rpcProvider.broadcastHex(data)
    }
    
    func tokenBalance(address: String, token: Token) -> AnyPublisher<(Token, Decimal), Error> {
        rpcProvider.tokenBalance(address: address, contractAddress: token.contractAddress)
            .tryMap { response in
                guard let hexValue = response.constant_result.first else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                let bigIntValue = BigUInt(Data(hex: hexValue))
                
                let formatted = Web3.Utils.formatToPrecision(
                    bigIntValue,
                    numberDecimals: token.decimalCount,
                    formattingDecimals: token.decimalCount,
                    decimalSeparator: ".",
                    fallbackToScientific: false
                )
                
                guard let decimalValue = Decimal(formatted) else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                return (token, decimalValue)
            }
            .eraseToAnyPublisher()
    }
    
    func transactionConfirmed(id: String) -> AnyPublisher<String?, Error> {
        rpcProvider.transactionInfo(id: id)
            .map { _ in
                return id
            }
            .tryCatch { error -> AnyPublisher<String?, Error> in
                if case WalletError.failedToParseNetworkResponse = error {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                throw error
            }
            .eraseToAnyPublisher()
    }
    
    func tokenTransferMaxEnergyUse(contractAddress: String) -> AnyPublisher<Int, Error> {
        rpcProvider.tokenTransactionHistory(contractAddress: contractAddress)
            .tryMap {
                guard let maxEnergyUsage = $0.data.map(\.energy_usage_total).max() else {
                    throw WalletError.failedToGetFee
                }
                
                return maxEnergyUsage
            }
            .eraseToAnyPublisher()
    }

    func getAccountResource(for address: String) -> AnyPublisher<TronGetAccountResourceResponse, Error> {
        rpcProvider.getAccountResource(for: address)
    }
    
    func accountExists(address: String) -> AnyPublisher<Bool, Error> {
        rpcProvider.getAccount(for: address)
            .map { _ in
                true
            }
            .tryCatch { error -> AnyPublisher<Bool, Error> in
                if case WalletError.failedToParseNetworkResponse = error {
                    return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                throw error
            }
            .eraseToAnyPublisher()
    }
}
