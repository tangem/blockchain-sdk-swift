//
//  EthereumNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 18.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import SwiftyJSON
import web3swift
import BigInt

class EthereumNetworkService: MultiNetworkProvider {
    let providers: [EthereumJsonRpcProvider]
    var currentProviderIndex: Int = 0
    
    private let decimals: Int
    private let ethereumInfoNetworkProvider: EthereumAdditionalInfoProvider?
    private let transactionHistoryProvider: TransactionHistoryProvider?
    private let abiEncoder: ABIEncoder
    
    init(
        decimals: Int,
        providers: [EthereumJsonRpcProvider],
        blockcypherProvider: BlockcypherNetworkProvider?,
        transactionHistoryProvider: TransactionHistoryProvider?,
        abiEncoder: ABIEncoder
    ) {
        self.providers = providers
        self.decimals = decimals
        self.ethereumInfoNetworkProvider = blockcypherProvider
        self.transactionHistoryProvider = transactionHistoryProvider
        self.abiEncoder = abiEncoder
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
                .tryMap {[weak self] in
                    guard let self = self else { throw WalletError.empty }
                    
                    return try self.getResult(from: $0) }
                .eraseToAnyPublisher()
        }
    }
    
    func getInfo(address: String, tokens: [Token]) -> AnyPublisher<EthereumInfoResponse, Error> {
        Publishers.Zip4(
            getBalance(address),
            getTokensBalance(address, tokens: tokens),
            getTxCount(address),
            getPendingTxCount(address)
        )
            .map { (result: (Decimal, [Token: Decimal], Int, Int)) in
                EthereumInfoResponse(balance: result.0, tokenBalances: result.1, txCount: result.2, pendingTxCount: result.3, pendingTxs: [])
            }
            .flatMap { [weak self] resp -> AnyPublisher<EthereumInfoResponse, Error> in
                guard let self = self else { return .emptyFail }
                
                guard
                    let provider = self.ethereumInfoNetworkProvider,
                    resp.pendingTxCount > 0,
                    self.transactionHistoryProvider == nil // We don't want to load pending txs if history is available
                else {
                    return .justWithError(output: resp)
                }
                
                return provider.getEthTxsInfo(address: address)
                    .map { ethResponse -> EthereumInfoResponse in
                        var newResp = resp
                        newResp.pendingTxs = ethResponse.pendingTxs
                        return newResp
                    }
                    .replaceError(with: resp)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumFeeResponse, Error> {
        let gasPricePublisher = getGasPrice()
        let gasLimitPublisher = getGasLimit(to: to, from: from, value: value, data: data)
        
        return Publishers.Zip(gasPricePublisher, gasLimitPublisher)
            .tryMap {[weak self] gasPrice, gasLimit -> EthereumFeeResponse in
                guard let self = self else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                return self.mapToEthereumFeeResponse(
                    gasPrice: gasPrice,
                    gasLimit: gasLimit,
                    decimalCount: self.decimals
                )
            }
            .mapError { error in
                if let moyaError = error as? MoyaError,
                   let responseData = moyaError.response?.data,
                   let ethereumResponse = try? JSONDecoder().decode(EthereumResponse.self, from: responseData),
                   let errorMessage = ethereumResponse.error?.message,
                   errorMessage.contains("gas required exceeds allowance", ignoreCase: true) {
                    return ETHError.gasRequiredExceedsAllowance
                }
                
                return error
            }
            .eraseToAnyPublisher()
    }
    
    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
       providerPublisher { provider in
           provider.getTxCount(for: address)
               .tryMap {[weak self] in
                   guard let self = self else { throw WalletError.empty }
                   
                   return try self.getTxCount(from: $0)
               }
               .eraseToAnyPublisher()
       }
   }
    
    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasPrice()
                .tryMap {[weak self] in
                    guard let self = self else { throw WalletError.empty }
                    
                    return try self.getGas(from: $0)
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasLimit(to: to, from: from, value: value, data: data)
                .tryMap {[weak self] in
                    guard let self = self else { throw WalletError.empty }
                    
                    return try self.getGas(from: $0)
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .flatMap {[weak self] token in
                self?.providerPublisher { provider in
                    provider.getTokenBalance(for: address, contractAddress: token.contractAddress)
                        .tryMap {[weak self] resp -> Decimal in
                            guard let self = self else { throw WalletError.empty }
                            
                            let result = try self.getResult(from: resp)
                            guard let value = EthereumUtils.parseEthereumDecimal(result, decimalsCount: token.decimalCount) else {
                                throw ETHError.failedToParseBalance(value: result, address: token.contractAddress, decimals: token.decimalCount)
                            }
                            
                            return value
                        }
                        .map { (token, $0) }
                        .eraseToAnyPublisher()
                } ?? .emptyFail
            }
            .collect()
            .map { $0.reduce(into: [Token: Decimal]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        guard let networkProvider = ethereumInfoNetworkProvider else {
            return Fail(error: ETHError.unsupportedFeature).eraseToAnyPublisher()
        }
        
        return networkProvider.getSignatureCount(address: address)
    }

    func getAllowance(from: String, to: String, contractAddress: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.getAllowance(from: from, to: to, contractAddress: contractAddress)
                .tryMap { [weak self] in
                    guard let self = self else { throw WalletError.empty }

                    return try self.getResult(from: $0)
                  }
                .eraseToAnyPublisher()
        }
    }
    
    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            provider.getBalance(for: address)
                .tryMap {[weak self] in
                    guard let self = self else { throw WalletError.empty }
                    
                    let result = try self.getResult(from: $0)
                    guard let value = EthereumUtils.parseEthereumDecimal(result, decimalsCount: self.decimals) else {
                        throw ETHError.failedToParseBalance(value: result, address: address, decimals: self.decimals)
                    }
                    
                    return value
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.getPendingTxCount(for: address)
                .tryMap {[weak self] in
                    guard let self = self else { throw WalletError.empty }
                    
                    return try self.getTxCount(from: $0)
                }
                .eraseToAnyPublisher()
        }
    }
    
    func read<Target: SmartContractTargetType>(target: Target) -> AnyPublisher<String, Error> {
        let encodedData = abiEncoder.encode(method: target.methodName, parameters: target.parameters)

        return providerPublisher {
            $0.read(contractAddress: target.contactAddress, encodedData: encodedData)
                .tryMap { [weak self] in
                    guard let self = self else { throw WalletError.empty }
                    
                    return try self.getResult(from: $0)
                }
                .eraseToAnyPublisher()
        }
    }
    
    
    // MARK: - Private functions
    
    private func getGas(from response: EthereumResponse) throws -> BigUInt {
        let res = try getResult(from: response)
        guard let count = BigUInt(res.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseGasLimit
        }
        
        return count
    }
    
    private func getTxCount(from response: EthereumResponse) throws -> Int {
        let countString = try getResult(from: response)
        guard let count = Int(countString.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseTxCount
        }
        
        return count
    }
    
    private func getResult(from response: EthereumResponse) throws -> String {
        if let error = response.error {
            throw error.error
        }
        
        guard let result = response.result else {
            throw WalletError.failedToParseNetworkResponse
        }
        
        return result
    }
    
    private func mapToEthereumFeeResponse(gasPrice: BigUInt, gasLimit: BigUInt, decimalCount: Int) -> EthereumFeeResponse {
        let minGasPrice = gasPrice
        let normalGasPrice = gasPrice * BigUInt(12) / BigUInt(10)
        let maxGasPrice = gasPrice * BigUInt(15) / BigUInt(10)
        
        return EthereumFeeResponse(gasPrices: [minGasPrice, normalGasPrice, maxGasPrice], gasLimit: gasLimit)
    }
}

extension EthereumNetworkService: TransactionHistoryProvider {
    func loadTransactionHistory(address: String) -> AnyPublisher<[TransactionHistoryRecordConvertible], Error> {
        guard let historyProvider = transactionHistoryProvider else {
            return Fail(error: ETHError.unsupportedFeature).eraseToAnyPublisher()
        }
        
        return historyProvider.loadTransactionHistory(address: address)
    }
}
