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

    func getEIP1559Fee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumEIP1559FeeResponse, Error> {
        let gasLimitPublisher = getGasLimit(to: to, from: from, value: value, data: data)
        let feeHistoryPublisher = getFeeHistory()

        return Publishers.Zip(gasLimitPublisher, feeHistoryPublisher)
            .map { (gasLimit, feeHistory) -> EthereumEIP1559FeeResponse in
                return EthereumMapper.mapToEthereumEIP1559FeeResponse(
                    gasLimit: gasLimit,
                    feeHistory: feeHistory
                )
            }
            .mapError { EthereumMapper.mapError($0) }
            .eraseToAnyPublisher()
    }

    func getLegacyFee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumLegacyFeeResponse, Error> {
        let gasPricePublisher = getGasPrice()
        let gasLimitPublisher = getGasLimit(to: to, from: from, value: value, data: data)

        return Publishers.Zip(gasPricePublisher, gasLimitPublisher)
            .tryMap { (gasPrice, gasLimit) -> EthereumLegacyFeeResponse in
                return EthereumMapper.mapToEthereumLegacyFeeResponse(
                    gasPrice: gasPrice,
                    gasLimit: gasLimit
                )
            }
            .mapError { EthereumMapper.mapError($0) }
            .eraseToAnyPublisher()
    }

    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
       providerPublisher { provider in
           provider.getTxCount(for: address)
               .tryMap { try EthereumMapper.mapInt($0) }
               .eraseToAnyPublisher()
       }
   }

    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error> {
        providerPublisher {
            $0.getFeeHistory()
                .tryMap { try EthereumMapper.mapFeeHistory($0) }
                .eraseToAnyPublisher()
        }
    }

    func getPriorityFee() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getPriorityFee()
                .tryMap { try EthereumMapper.mapBigUInt($0) }
                .eraseToAnyPublisher()
        }
    }

    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasPrice()
                .tryMap { try EthereumMapper.mapBigUInt($0) }
                .eraseToAnyPublisher()
        }
    }
    
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        providerPublisher {
            $0.getGasLimit(to: to, from: from, value: value, data: data)
                .tryMap { try EthereumMapper.mapBigUInt($0) }
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
                .tryMap { try EthereumMapper.mapInt($0) }
                .eraseToAnyPublisher()
        }
    }
    
    func read<Target: SmartContractTargetType>(target: Target) -> AnyPublisher<String, Error> {
        let encodedData = abiEncoder.encode(method: target.methodName, parameters: target.parameters)

        return providerPublisher {
            $0.call(contractAddress: target.contactAddress, encodedData: encodedData)
        }
    }
}

extension EthereumNetworkService: EVMSmartContractInteractor {
    func ethCall<Request>(request: Request) -> AnyPublisher<String, Error> where Request : SmartContractRequest {
        return providerPublisher {
            $0.call(contractAddress: request.contractAddress, encodedData: request.encodedData)
        }
    }
}

// MARK: - EthereumErrorMapper

fileprivate struct EthereumMapper {
    static func mapError(_ error: Error) -> Error {
        if let moyaError = error as? MoyaError,
           let responseData = moyaError.response?.data,
           let ethereumResponse = try? JSONDecoder().decode(JSONRPC.Response<String, JSONRPC.APIError>.self, from: responseData),
           let errorMessage = ethereumResponse.result.error?.message,
           errorMessage.contains("gas required exceeds allowance", ignoreCase: true) {
            return ETHError.gasRequiredExceedsAllowance
        }

        return error
    }

    static func mapBigUInt(_ response: String) throws -> BigUInt {
        guard let value = BigUInt(response.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseGasLimit
        }

        return value
    }

    static func mapInt(_ response: String) throws -> Int {
        guard let value = Int(response.removeHexPrefix(), radix: 16) else {
            throw ETHError.failedToParseGasLimit
        }

        return value
    }

    //TODO: Move Estimate from mapper in NetworkService
    static func mapFeeHistory(_ response: EthereumFeeHistoryResponse) throws -> EthereumFeeHistory {
        guard !response.baseFeePerGas.isEmpty,
              !response.reward.isEmpty else {
            throw ETHError.failedToParseFeeHistory
        }

        // This is an actual baseFee for a pending block
        guard let pendingBaseFeeString = response.baseFeePerGas.last else {
            throw ETHError.failedToParseFeeHistory
        }

        let pendingBaseFee = try mapBigUInt(pendingBaseFeeString)

        var lowSum: BigUInt = 0
        var marketSum: BigUInt = 0
        var fastSum: BigUInt = 0

        try response.reward.forEach {
            guard let lowString = $0[safe: 0],
                  let marketString  = $0[safe: 1],
                  let fastString = $0[safe: 2] else {
                throw ETHError.failedToParseFeeHistory
            }

            lowSum += try mapBigUInt(lowString)
            marketSum += try mapBigUInt(marketString)
            fastSum += try mapBigUInt(fastString)
        }

        let blocksCount = BigUInt(response.reward.count)

        let lowAverage = lowSum / blocksCount
        let marketAverage = marketSum / blocksCount
        let fastAverage = fastSum / blocksCount

        let lowBaseFee = pendingBaseFee * BigUInt(125) / BigUInt(100) // +12.5%
        let marketBaseFee = pendingBaseFee * BigUInt(150) / BigUInt(100) // +50%
        let fastBaseFee = pendingBaseFee * BigUInt(2) // + 100%

        let feeHistory = EthereumFeeHistory(
            baseFee: pendingBaseFee,
            lowBaseFee: lowBaseFee,
            marketBaseFee: marketBaseFee,
            fastBaseFee: fastBaseFee,
            lowPriorityFee: lowAverage,
            marketPriorityFee: marketAverage,
            fastPriorityFee: fastAverage
        )

        return feeHistory
    }

    static func mapToEthereumEIP1559FeeResponse(gasLimit: BigUInt, feeHistory: EthereumFeeHistory) -> EthereumEIP1559FeeResponse {
        return EthereumEIP1559FeeResponse(
            gasLimit: gasLimit,
            fees: (
                low: .init(max: feeHistory.lowBaseFee + feeHistory.lowPriorityFee, priority: feeHistory.lowPriorityFee),
                market: .init(max: feeHistory.marketBaseFee + feeHistory.marketPriorityFee, priority: feeHistory.marketPriorityFee),
                fast: .init(max: feeHistory.fastBaseFee + feeHistory.fastPriorityFee, priority: feeHistory.fastPriorityFee)
            )
        )
    }

    static func mapToEthereumLegacyFeeResponse(gasPrice: BigUInt, gasLimit: BigUInt) -> EthereumLegacyFeeResponse {
        let minGasPrice = gasPrice
        let normalGasPrice = gasPrice * BigUInt(12) / BigUInt(10)
        let maxGasPrice = gasPrice * BigUInt(15) / BigUInt(10)

        return EthereumLegacyFeeResponse(
            gasLimit: gasLimit,
            lowGasPrice: minGasPrice,
            marketGasPrice: normalGasPrice,
            fastGasPrice: maxGasPrice
        )
    }
}
