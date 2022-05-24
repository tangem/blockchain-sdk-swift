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
    let blockchain: Blockchain
    let rpcProvider: TronJsonRpcProvider
    
    init(blockchain: Blockchain, rpcProvider: TronJsonRpcProvider) {
        self.blockchain = blockchain
        self.rpcProvider = rpcProvider
    }
    
    func accountInfo(for address: String, tokens: [Token], transactionIDs: [String]) -> AnyPublisher<TronAccountInfo, Error> {
        let blockchain = self.blockchain
        let tokenBalancePublishers = tokens.map {
            tokenBalance(address: address, token: $0).setFailureType(to: Error.self)
        }
        let confirmedTransactionPublishers = transactionIDs.map { transactionConfirmed(id: $0) }
        
        return rpcProvider.getAccount(for: address)
            .tryCatch { error -> AnyPublisher<TronGetAccountResponse, Error> in
                if case WalletError.failedToParseNetworkResponse = error {
                    return Just(TronGetAccountResponse(balance: 0, address: address)).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                throw error
            }
            .zip(Publishers.MergeMany(tokenBalancePublishers).collect(),
                 Publishers.MergeMany(confirmedTransactionPublishers).collect())
            .map { (accountInfo, tokenInfoList, confirmedTransactionList) in
                let balance = Decimal(accountInfo.balance ?? 0) / blockchain.decimalValue
                let tokenBalances = Dictionary(uniqueKeysWithValues: tokenInfoList)
                let confirmedTransactionIDs = confirmedTransactionList.compactMap { $0 }
                
                return TronAccountInfo(balance: balance, tokenBalances: tokenBalances, confirmedTransactionIDs: confirmedTransactionIDs)
            }
            .eraseToAnyPublisher()
    }
    
    func getNowBlock() -> AnyPublisher<TronBlock, Error> {
        rpcProvider.getNowBlock()
    }
    
    func broadcastHex(_ data: Data) -> AnyPublisher<TronBroadcastResponse, Error> {
        rpcProvider.broadcastHex(data)
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
    
    private func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        rpcProvider.getAccount(for: address)
    }
    
    private func tokenBalance(address: String, token: Token) -> AnyPublisher<(Token, Decimal), Never> {
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
            .replaceError(with: (token, .zero))
            .eraseToAnyPublisher()
    }
    
    private func transactionConfirmed(id: String) -> AnyPublisher<String?, Error> {
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
}
