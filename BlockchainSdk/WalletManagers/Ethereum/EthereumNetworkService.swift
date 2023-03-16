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
    private let blockchairProvider: BlockchairNetworkProvider?
    private let transactionHistoryProvider: TransactionHistoryProvider?
    
    init(decimals: Int,
         providers: [EthereumJsonRpcProvider],
         blockcypherProvider: BlockcypherNetworkProvider?,
         blockchairProvider: BlockchairNetworkProvider?,
         transactionHistoryProvider: TransactionHistoryProvider?) {
        self.providers = providers
        self.decimals = decimals
        self.ethereumInfoNetworkProvider = blockcypherProvider
        self.blockchairProvider = blockchairProvider
        self.transactionHistoryProvider = transactionHistoryProvider
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
        let gasPricePublishers = Publishers.MergeMany(
            providers.map {
                parseGas($0.getGasPrice()).toResultPublisher()
            }
        ).collect()
        
        let gasLimitPublishers = Publishers.MergeMany(
            providers.map {
                parseGas($0.getGasLimit(to: to, from: from, value: value, data: data)).toResultPublisher()
                
            }
        ).collect()
        
        return Publishers.Zip(gasPricePublishers, gasLimitPublishers)
            .tryMap {[weak self] gasPrices, gasLimits -> EthereumFeeResponse in
                guard let self = self else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                return try self.mapToEthereumFeeResponse(
                    gasPrice: maxGas(gasPrices),
                    gasLimit: maxGas(gasLimits),
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
    
    func findErc20Tokens(address: String) -> AnyPublisher<[BlockchairToken], Error> {
        guard let blockchairProvider = blockchairProvider else {
            return Fail(error: ETHError.unsupportedFeature).eraseToAnyPublisher()
        }
        
        return blockchairProvider.findErc20Tokens(address: address)
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
    
    private func mapToEthereumFeeResponse(gasPrice: BigUInt, gasLimit: BigUInt, decimalCount: Int) throws -> EthereumFeeResponse {
        let minValue = gasPrice * gasLimit
        let normalValue = gasPrice * BigUInt(12) / BigUInt(10) * gasLimit
        let maxValue = gasPrice * BigUInt(15) / BigUInt(10) * gasLimit
        
        let values = [minValue, normalValue, maxValue]

        let decimals = values
            .compactMap { value in
                Web3.Utils.formatToEthereumUnits(
                    value,
                    toUnits: .eth,
                    decimals: decimalCount,
                    decimalSeparator: ".",
                    fallbackToScientific: false
                )
            }.compactMap { value in
                Decimal(string: value)
            }
        
        guard values.count == decimals.count else {
            throw WalletError.failedToGetFee
        }
        
        return EthereumFeeResponse(
            fees: decimals,
            parameters: EthereumFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice)
        )
    }
    
    private func parseGas(_ publisher: AnyPublisher<EthereumResponse, Error>) -> AnyPublisher<BigUInt, Error> {
        publisher.tryMap {[weak self] in
            guard let self = self else { throw WalletError.empty }
            
            return try self.getGas(from: $0)
        }
        .eraseToAnyPublisher()
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

// MARK: - Gas price / gas limit helpers

fileprivate extension AnyPublisher where Output == BigUInt, Failure == Error {
    func toResultPublisher() -> AnyPublisher<Result<BigUInt, Error>, Never> {
        map {
            Result<BigUInt, Error>.success($0)
        }.catch {
            Just<Result<BigUInt, Error>>(.failure($0))
        }
        .eraseToAnyPublisher()
    }
}

fileprivate func maxGas(_ results: [Result<BigUInt, Error>]) throws -> BigUInt {
    if let maxSuccessValue = results.maxSuccessValue {
        return maxSuccessValue
    } else if let firstFailureError = results.firstFailureError {
        throw firstFailureError
    } else {
        throw WalletError.failedToGetFee
    }
}

fileprivate extension Array where Element == Result<BigUInt, Error> {
    var maxSuccessValue: BigUInt? {
        compactMap {
            guard case let .success(value) = $0 else { return nil }
            return value
        }
        .max()
    }
    
    var firstFailureError: Error? {
        compactMap {
            guard case let .failure(error) = $0 else { return nil }
            return error
        }
        .first
    }
}
