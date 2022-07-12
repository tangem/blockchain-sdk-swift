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
        Publishers.Zip3(
            getAccount(for: address),
            tokenBalances(address: address, tokens: tokens),
            confirmedTransactionIDs(ids: transactionIDs)
        )
        .map { [blockchain] (accountInfo, tokenBalances, confirmedTransactionIDs) in
            let balance = Decimal(accountInfo.balance ?? 0) / blockchain.decimalValue
            return TronAccountInfo(
                balance: balance,
                tokenBalances: tokenBalances,
                confirmedTransactionIDs: confirmedTransactionIDs
            )
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
                guard let maxEnergyUsage = $0.data.compactMap(\.energy_usage_total).max() else {
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
            .tryCatch { error -> AnyPublisher<TronGetAccountResponse, Error> in
                if case WalletError.failedToParseNetworkResponse = error {
                    return Just(TronGetAccountResponse(balance: 0, address: address))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                throw error
            }
            .eraseToAnyPublisher()
    }
    
    private func tokenBalances(address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] token -> AnyPublisher<(Token, Decimal), Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                return self
                    .tokenBalance(address: address, token: token)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .collect()
            .map {
                $0.reduce(into: [:]) { tokenBalances, tokenBalance in
                    tokenBalances[tokenBalance.0] = tokenBalance.1
                }
            }
            .eraseToAnyPublisher()
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
    
    private func confirmedTransactionIDs(ids transactionIDs: [String]) -> AnyPublisher<[String], Error> {
        transactionIDs
            .publisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] transactionID -> AnyPublisher<String?, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                return self.transactionConfirmed(id: transactionID)
            }
            .collect()
            .map {
                $0.reduce(into: []) { confirmedTransactionIDs, confirmedTransactionID in
                    if let confirmedTransactionID = confirmedTransactionID {
                        confirmedTransactionIDs.append(confirmedTransactionID)
                    }
                }
            }
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
