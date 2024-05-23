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
        .map { balance, tokenBalances, txCount, pendingTxCount in
            EthereumInfoResponse(
                balance: balance,
                tokenBalances: tokenBalances,
                txCount: txCount,
                pendingTxCount: pendingTxCount,
                pendingTxs: []
            )
        }
        .eraseToAnyPublisher()
    }

    func getFee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumFeeResponse, Error> {
        let gasLimitPublisher = getGasLimit(to: to, from: from, value: value, data: data)
        let baseFeePublisher = getBaseFee()
        let priorityFeePublisher = getPriorityFee()

        return Publishers.Zip3(gasLimitPublisher, baseFeePublisher, priorityFeePublisher)
            .withWeakCaptureOf(self)
            .tryMap { networkService, args in
                let (gasLimit, baseFee, priorityFee) = args

                return networkService.mapToEthereumFeeResponse(
                    baseFee: baseFee,
                    priorityFee: priorityFee,
                    gasLimit: gasLimit
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
               .withWeakCaptureOf(self)
               .tryMap { networkService, result in
                   try networkService.getTxCount(from: result)
               }
               .eraseToAnyPublisher()
       }
   }

    func getBaseFee() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getFeeHistory()
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    try service.getBaseFee(response: response)
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
                .withWeakCaptureOf(self)
                .tryMap { networkService, result in
                    try networkService.getTxCount(from: result)
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

    private func getBaseFee(response: EthereumFeeHistoryResponse) throws -> BigUInt {
        guard !response.baseFeePerGas.isEmpty else {
            throw ETHError.failedToParseBaseFees
        }

        let baseFeePerGas = response.baseFeePerGas.compactMap {
            EthereumUtils.parseEthereumDecimal($0, decimalsCount: 0)
        }

        let average = baseFeePerGas.reduce(0, +) / Decimal(baseFeePerGas.count)
        let bigUInt = EthereumUtils.mapToBigUInt(average)
        return bigUInt
    }

    private func mapToEthereumFeeResponse(baseFee: BigUInt, priorityFee: BigUInt, gasLimit: BigUInt) -> EthereumFeeResponse {
        let lowBaseFee = baseFee * BigUInt(85) / BigUInt(100) // - 15%
        let marketBaseFee = baseFee
        let fastBaseFee = baseFee * BigUInt(115) / BigUInt(100) // + 15%

        // We can't decrease priorityFee for the lowest fee option
        let lowPriorityFee = priorityFee
        let marketPriorityFee = priorityFee
        // The priorityFee usually is between 1-3 GWEI. We can increase it to accelerate the transaction
        let fastPriorityFee = priorityFee * BigUInt(2)

        return EthereumFeeResponse(
            gasLimit: gasLimit,
            fees: (
                low: .init(base: lowBaseFee, priority: lowPriorityFee),
                market: .init(base: marketBaseFee, priority: marketPriorityFee),
                fast: .init(base: fastBaseFee, priority: fastPriorityFee)
            )
        )
    }
}

extension EthereumNetworkService: EVMSmartContractInteractor {
    func ethCall<Request>(request: Request) -> AnyPublisher<String, Error> where Request : SmartContractRequest {
        return providerPublisher {
            $0.call(contractAddress: request.contractAddress, encodedData: request.encodedData)
        }
    }
}
