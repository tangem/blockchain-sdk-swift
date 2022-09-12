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
    
    init(decimals: Int,
         providers: [EthereumJsonRpcProvider],
         blockcypherProvider: BlockcypherNetworkProvider?,
         blockchairProvider: BlockchairNetworkProvider?) {
        self.providers = providers
        self.decimals = decimals
        self.ethereumInfoNetworkProvider = blockcypherProvider
        self.blockchairProvider = blockchairProvider
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
                
                guard let provider = self.ethereumInfoNetworkProvider, resp.pendingTxCount > 0 else {
                    return .justWithError(output: resp)
                }
                
                return provider.getEthTxsInfo(address: address)
                    .map { ethResponse -> EthereumInfoResponse in
                        var newResp = resp
                        newResp.pendingTxs = ethResponse.pendingTxs
                        return newResp
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(to: String, from: String, value: String?, data: String?, fallbackGasLimit: BigUInt?) -> AnyPublisher<EthereumFeeResponse, Error> {
        return Publishers.Zip(
            Publishers.MergeMany(providers.map { parseGas($0.getGasPrice()) }).collect(),
            Publishers.MergeMany(providers.map { parseGas($0.getGasLimit(to: to, from: from, value: value, data: data)) }).collect()
        )
            .tryMap {[weak self] (result: ([BigUInt], [BigUInt])) -> EthereumFeeResponse in
                guard let self = self else { throw WalletError.empty }
                
                guard !result.0.isEmpty else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let maxPrice = result.0.max()!
                let maxLimit = result.1.max()
                if maxLimit == nil, fallbackGasLimit == nil {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let maxGasLimit = maxLimit ?? fallbackGasLimit!
                let fees = try self.calculateFee(gasPrice: maxPrice, gasLimit: maxGasLimit, decimalCount: self.decimals)
                return EthereumFeeResponse(fees: fees, gasLimit: maxGasLimit)
            }
            .eraseToAnyPublisher()
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
    
    // MARK: - Private functions
    
    private func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
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
    
    private func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        providerPublisher { provider in
            provider.getTxCount(for: address)
                .tryMap {[weak self] in
                    guard let self = self else { throw WalletError.empty }
                    
                    return try self.getTxCount(from: $0)
                }
                .eraseToAnyPublisher()
        }
    }
    
    private func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.getPendingTxCount(for: address)
                .tryMap {[weak self] in
                    guard let self = self else { throw WalletError.empty }
                    
                    return try self.getTxCount(from: $0)
                }
                .eraseToAnyPublisher()
        }
    }
    
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
    
    private func calculateFee(gasPrice: BigUInt, gasLimit: BigUInt, decimalCount: Int) throws -> [Decimal] {
        let minValue = gasPrice * gasLimit
        let min = Web3.Utils.formatToEthereumUnits(minValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
        
        let normalValue = gasPrice * BigUInt(12) / BigUInt(10) * gasLimit
        let normal = Web3.Utils.formatToEthereumUnits(normalValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
        
        let maxValue = gasPrice * BigUInt(15) / BigUInt(10) * gasLimit
        let max = Web3.Utils.formatToEthereumUnits(maxValue, toUnits: .eth, decimals: decimalCount, decimalSeparator: ".", fallbackToScientific: false)!
        
        guard let minDecimal = Decimal(string: min),
              let normalDecimal = Decimal(string: normal),
              let maxDecimal = Decimal(string: max) else {
                  throw WalletError.failedToGetFee
              }
        
        return [minDecimal, normalDecimal, maxDecimal]
    }
    
    private func parseGas(_ publisher: AnyPublisher<EthereumResponse, Error>) -> AnyPublisher<BigUInt, Never> {
        publisher.tryMap {[weak self] in
            guard let self = self else { throw WalletError.empty }
            
            return try self.getGas(from: $0)
        }
        .replaceError(with: 0)
        .filter { $0 > 0 }
        .eraseToAnyPublisher()
    }
}

