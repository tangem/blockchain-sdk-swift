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

class EthereumNetworkService: MultiNetworkProvider<EthereumJsonRpcProvider> {
    
    var host: String {
        provider.host
    }
    
    private let network: EthereumNetwork
    private let jsonRpcProvider: [EthereumJsonRpcProvider] = []

    private let blockcypherProvider: BlockcypherNetworkProvider?
    private let blockchairProvider: BlockchairEthNetworkProvider?
    
    init(network: EthereumNetwork, providers: [EthereumJsonRpcProvider], blockcypherProvider: BlockcypherNetworkProvider?, blockchairProvider: BlockchairEthNetworkProvider?) {
        self.network = network
        self.blockcypherProvider = blockcypherProvider
        self.blockchairProvider = blockchairProvider
        super.init(providers: providers)
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
                .tryMap { try self.getResult(from: $0) }
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
            EthereumInfoResponse(balance: result.0, tokenBalances: result.1, txCount: result.2, pendingTxCount: result.3)
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(to: String, from: String, data: String?, fallbackGasLimit: BigUInt?) -> AnyPublisher<EthereumFeeResponse, Error> {
        func parseGas(_ publisher: AnyPublisher<EthereumResponse, Error>) -> AnyPublisher<BigUInt, Never> {
            publisher.tryMap { try self.getGas(from: $0) }
                .replaceError(with: 0)
                .filter { $0 > 0 }
                .eraseToAnyPublisher()
        }
        
        return Publishers.Zip(
            Publishers.MergeMany(providers.map { parseGas($0.getGasPrice()) }).collect(),
            Publishers.MergeMany(providers.map { parseGas($0.getGasLimit(to: to, from: from, data: data)) }).collect()
        )
        .tryMap { (result: ([BigUInt], [BigUInt])) -> EthereumFeeResponse in
            guard result.0.count > 0 else {
                throw BlockchainSdkError.failedToLoadFee
            }
            
            let maxPrice = result.0.max()!
            let maxLimit = result.1.max()
            if maxLimit == nil, fallbackGasLimit == nil {
                throw BlockchainSdkError.failedToLoadFee
            }
            
            let maxGasLimit = maxLimit ?? fallbackGasLimit!
            let fees = try self.calculateFee(gasPrice: maxPrice, gasLimit: maxGasLimit, decimalCount: self.network.blockchain.decimalCount)
            return EthereumFeeResponse(fees: fees, gasLimit: maxGasLimit)
        }
        .eraseToAnyPublisher()
    }
    
    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasPrice()
                .tryMap { try self.getGas(from: $0) }
                .eraseToAnyPublisher()
        }
    }
    
    func getGasLimit(to: String, from: String, data: String?) -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasLimit(to: to, from: from, data: data)
                .tryMap { try self.getGas(from: $0) }
                .eraseToAnyPublisher()
        }
    }
    
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] token in
                self.providerPublisher { provider in
                    provider.getTokenBalance(for: address, contractAddress: token.contractAddress)
                        .tryMap { resp -> Decimal in
                            let result = try self.getResult(from: resp)
                            
                            return try EthereumUtils.parseEthereumDecimal(result, decimalsCount: token.decimalCount)
                        }
                        .map { (token, $0) }
                        .eraseToAnyPublisher()
                }
            }
            .collect()
            .map { $0.reduce(into: [Token: Decimal]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }
    
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        guard let blockcypherProvider = blockcypherProvider else {
            return Fail(error: ETHError.unsupportedFeature).eraseToAnyPublisher()
        }
        
		return blockcypherProvider.getSignatureCount(address: address)
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
                .tryMap { try EthereumUtils.parseEthereumDecimal(self.getResult(from: $0), decimalsCount: self.network.blockchain.decimalCount) }
                .eraseToAnyPublisher()
        }
    }
    
    private func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        providerPublisher { provider in
            provider.getTxCount(for: address)
                .tryMap { try self.getTxCount(from: $0) }
                .eraseToAnyPublisher()
        }
    }
    
    private func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.getPendingTxCount(for: address)
                .tryMap { try self.getTxCount(from: $0) }
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
}

