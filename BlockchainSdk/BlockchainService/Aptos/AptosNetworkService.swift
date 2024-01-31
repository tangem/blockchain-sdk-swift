//
//  AptosNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 29.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftyJSON

class AptosNetworkService: MultiNetworkProvider {
    // MARK: - Protperties
    
    let blockchain: Blockchain
    let providers: [AptosNetworkProvider]
    var currentProviderIndex: Int = 0
    
    // MARK: - Init
    
    init(blockchain: Blockchain, providers: [AptosNetworkProvider]) {
        self.blockchain = blockchain
        self.providers = providers
    }
    
    // MARK: - Implementation
    
    func getAccount(address: String) -> AnyPublisher<AptosAccountInfo, Error> {
        providerPublisher { provider in
            provider
                .getAccountResources(address: address)
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    guard
                        let accountJson = response.arrayValue.first(where: { $0[JSONParseKey.type].stringValue == Constants.accountKeyPrefix }),
                        let coinJson = response.arrayValue.first(where: { $0[JSONParseKey.type].stringValue == Constants.coinStoreKeyPrefix })
                    else {
                        throw WalletError.failedToParseNetworkResponse
                    }
                    
                    let balanceValue = coinJson[JSONParseKey.data][JSONParseKey.coin][JSONParseKey.value].uInt64Value
                    let decimalBalanceValue = Decimal(balanceValue) / service.blockchain.decimalValue
                    
                    return AptosAccountInfo(
                        sequenceNumber: accountJson[JSONParseKey.data][JSONParseKey.sequenceNumber].int64Value,
                        balance: decimalBalanceValue
                    )
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getGasUnitPrice() -> AnyPublisher<AptosEstimatedGasPrice, Error> {
        providerPublisher { provider in
            provider
                .getGasUnitPrice()
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    let gasEstimate = Decimal(response[JSONParseKey.sequenceNumber].uInt64Value) / service.blockchain.decimalValue
                    return AptosEstimatedGasPrice(gasEstimate: gasEstimate)
                }
                .eraseToAnyPublisher()
        }
    }

    func calculateUsedGasPriceUnit(info: AptosTransactionInfo) -> AnyPublisher<AptosEstimatedGasPrice, Error> {
        providerPublisher { provider in
            provider
                .calculateUsedGasPriceUnit(
                    // Simple map domain model into dto model
                    transactionInfo: .init(
                        sequenceNumber: info.sequenceNumber,
                        publicKey: info.publicKey,
                        sourceAddress: info.sourceAddress,
                        destinationAddress: info.destinationAddress,
                        amount: info.amount,
                        contractAddress: info.contractAddress,
                        gasUnitPrice: info.gasUnitPrice,
                        maxGasAmount: info.maxGasAmount,
                        expirationTimestamp: info.expirationTimestamp,
                        hash: info.hash
                    )
                )
                .withWeakCaptureOf(self)
                .tryMap { service, response in
                    let gasEstimate = Decimal(response[JSONParseKey.sequenceNumber].uInt64Value) / service.blockchain.decimalValue
                    return AptosEstimatedGasPrice(gasEstimate: gasEstimate)
                }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Constants

private extension AptosNetworkService {
    enum Constants {
        static let accountKeyPrefix = "0x1::account::Account"
        static let coinStoreKeyPrefix = "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
    }
}

private extension AptosNetworkService {
    enum JSONParseKey: JSONSubscriptType {
        case sequenceNumber
        case type
        case data
        case value
        case coin
        case deprioritizedGasEstimate
        case gasEstimate
        case prioritizedGasEstimate
        
        var jsonKey: SwiftyJSON.JSONKey {
            switch self {
            case .sequenceNumber:
                return JSONKey.key("sequence_number")
            case .type:
                return JSONKey.key("type")
            case .data:
                return JSONKey.key("data")
            case .value:
                return JSONKey.key("value")
            case .coin:
                return JSONKey.key("coin")
            case .deprioritizedGasEstimate:
                return JSONKey.key("deprioritized_gas_estimate")
            case .gasEstimate:
                return JSONKey.key("gas_estimate")
            case .prioritizedGasEstimate:
                return JSONKey.key("prioritized_gas_estimate")
            }
        }
    }
}
