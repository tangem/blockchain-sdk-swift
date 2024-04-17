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
import BigInt

class EthereumNetworkService: MultiNetworkProvider {
    let providers: [EthereumJsonRpcProvider]
    var currentProviderIndex: Int = 0
    
    private let decimals: Int
    private let ethereumInfoNetworkProvider: EthereumAdditionalInfoProvider?
    private let abiEncoder: ABIEncoder
    
    init(
        decimals: Int,
        providers: [EthereumJsonRpcProvider],
        blockcypherProvider: BlockcypherNetworkProvider?,
        abiEncoder: ABIEncoder
    ) {
        self.providers = providers
        self.decimals = decimals
        self.ethereumInfoNetworkProvider = blockcypherProvider
        self.abiEncoder = abiEncoder
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
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
                   let ethereumResponse = try? JSONDecoder().decode(JSONRPC.Response<String, JSONRPC.APIError>.self, from: responseData),
                   let errorMessage = ethereumResponse.result.error?.message,
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

    func getBaseFee() -> AnyPublisher<Decimal, Error> {
        providerPublisher {
            $0.getFeeHistory()
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    service.getBaseFee(response: response)
                }
                .eraseToAnyPublisher()
        }
    }

    func getPriorityFee() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getPriorityFee()
                .withWeakCaptureOf(self)
                .tryMap { networkService, result in
                    try networkService.getGas(from: result)
                }
                .eraseToAnyPublisher()
        }
    }

    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasPrice()
                .withWeakCaptureOf(self)
                .tryMap { networkService, result in
                    try networkService.getGas(from: result)
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasLimit(to: to, from: from, value: value, data: data)
                .withWeakCaptureOf(self)
                .tryMap { networkService, result in
                    try networkService.getGas(from: result)
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { networkService, token in
                networkService.providerPublisher { provider -> AnyPublisher<(Token, Decimal), Error> in
                    let method = TokenBalanceERC20TokenMethod(owner: address)

                    return provider
                        .call(contractAddress: token.contractAddress, encodedData: method.encodedData)
                        .withWeakCaptureOf(networkService)
                        .tryMap { networkService, result in
                            guard let value = EthereumUtils.parseEthereumDecimal(result, decimalsCount: token.decimalCount) else {
                                throw ETHError.failedToParseBalance(value: result, address: token.contractAddress, decimals: token.decimalCount)
                            }
                            
                            return value
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
        guard let networkProvider = ethereumInfoNetworkProvider else {
            return Fail(error: ETHError.unsupportedFeature).eraseToAnyPublisher()
        }
        
        return networkProvider.getSignatureCount(address: address)
    }

    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<String, Error> {
        let method = AllowanceERC20TokenMethod(owner: owner, spender: spender)
        return providerPublisher {
            $0.call(contractAddress: contractAddress, encodedData: method.encodedData)
        }
    }
    
    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            provider.getBalance(for: address)
                .withWeakCaptureOf(self)
                .tryMap { networkService, result in
                    guard let value = EthereumUtils.parseEthereumDecimal(result, decimalsCount: networkService.decimals) else {
                        throw ETHError.failedToParseBalance(value: result, address: address, decimals: networkService.decimals)
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
            $0.call(contractAddress: target.contactAddress, encodedData: encodedData)
        }
    }
    
    
    // MARK: - Private functions
    
    private func getGas(from response: String) throws -> BigUInt {
        guard let count = BigUInt(response.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseGasLimit
        }

        return count
    }
    
    private func getTxCount(from response: String) throws -> Int {
        guard let count = Int(response.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseTxCount
        }
        
        return count
    }

    private func getBaseFee(response: EthereumFeeHistoryResponse) -> Decimal {
        let baseFeePerGas = response.baseFeePerGas.compactMap {
            EthereumUtils.parseEthereumDecimal($0, decimalsCount: decimals)
        }

        // Get the average value
        return baseFeePerGas.reduce(0, +) / Decimal(baseFeePerGas.count)
    }

    private func mapToEthereumFeeResponse(gasPrice: BigUInt, gasLimit: BigUInt, decimalCount: Int) -> EthereumFeeResponse {
        let minGasPrice = gasPrice
        let normalGasPrice = gasPrice * BigUInt(12) / BigUInt(10)
        let maxGasPrice = gasPrice * BigUInt(15) / BigUInt(10)
        
        return EthereumFeeResponse(gasPrices: [minGasPrice, normalGasPrice, maxGasPrice], gasLimit: gasLimit)
    }
}

extension EthereumNetworkService: EVMSmartContractInteractor {
    func ethCall<Request>(request: Request) -> AnyPublisher<String, Error> where Request : SmartContractRequest {
        return providerPublisher {
            $0.call(contractAddress: request.contractAddress, encodedData: request.encodedData)
        }
    }
}
