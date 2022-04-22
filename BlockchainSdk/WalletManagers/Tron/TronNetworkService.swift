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

class TronNetworkService {
    private let blockchain: Blockchain
    private let rpcProvider: TronJsonRpcProvider
    
    init(blockchain: Blockchain, rpcProvider: TronJsonRpcProvider) {
        self.blockchain = blockchain
        self.rpcProvider = rpcProvider
    }
    
    func accountInfo(for address: String, tokens: [Token]) -> AnyPublisher<TronAccountInfo, Error> {
        let blockchain = self.blockchain
        let tokenBalancePublishers = tokens.map { tokenBalance(address: address, token: $0) }
        
        return rpcProvider.getAccount(for: address)
            .zip(Publishers.MergeMany(tokenBalancePublishers).collect())
            .map { (accountInfo, tokenInfoList) in
                let balance = Decimal(accountInfo.balance) / blockchain.decimalValue
                let tokenBalances = Dictionary(uniqueKeysWithValues: tokenInfoList)
                
                return TronAccountInfo(balance: balance, tokenBalances: tokenBalances)
            }
            .eraseToAnyPublisher()
    }
    
    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        rpcProvider.getAccount(for: address)
    }
    
    func createTransaction(from source: String, to destination: String, amount: UInt64) -> AnyPublisher<TronTransactionRequest, Error> {
        rpcProvider.createTransaction(from: source, to: destination, amount: amount)
    }
    
    func createTrc20Transaction(from source: String, to destination: String, contractAddress: String, amount: UInt64) -> AnyPublisher<TronSmartContractTransactionRequest, Error> {
        rpcProvider.createTrc20Transaction(from: source, to: destination, contractAddress: contractAddress, amount: amount)
    }
    
    func broadcastTransaction(_ transaction: TronTransactionRequest) -> AnyPublisher<TronBroadcastResponse, Error> {
        rpcProvider.broadcastTransaction(transaction)
    }
    
    func broadcastTransaction2(_ transaction: TronTransactionRequest2) -> AnyPublisher<TronBroadcastResponse, Error> {
        rpcProvider.broadcastTransaction2(transaction)
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
    
    func getFee(amount: Amount, source: String, destination: String) -> AnyPublisher<[Amount], Error> {
        switch amount.type {
        case .coin:
            return rpcProvider.getAccountResource(for: source)
                .flatMap { r  -> AnyPublisher<[Amount], Error> in
                    print(r)
                    
                    return Just([Amount(with: .tron(testnet: true), value: 0.000001)])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        case .token(_):
            return Just([Amount(with: .tron(testnet: true), value: 0.000001)])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        default:
            return .anyFail(error: WalletError.failedToGetFee)
        }
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
