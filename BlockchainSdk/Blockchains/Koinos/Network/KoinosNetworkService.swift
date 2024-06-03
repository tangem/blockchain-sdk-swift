//
//  KoinosNetworkService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class KoinosNetworkService: MultiNetworkProvider {
    let providers: [KoinosNetworkProvider]
    var currentProviderIndex = 0
    private let satoshiMultiplier: Decimal
    
    init(providers: [KoinosNetworkProvider], decimalCount: Int) {
        self.providers = providers
        self.satoshiMultiplier = pow(10, decimalCount)
    }
    
    func getInfo(address: String) -> AnyPublisher<KoinosAccountInfo, Error> {
        providerPublisher { [satoshiMultiplier] provider in
            let balanceResult: AnyPublisher<UInt64, Error>
            let manaResult: AnyPublisher<UInt64, Error>
            
            do {
                balanceResult = try provider.getKoinBalance(address: address)
                manaResult = provider.getRC(address: address)
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
            
            return Publishers.Zip(
                balanceResult.map { Decimal($0) / satoshiMultiplier },
                manaResult.map { Decimal($0) / satoshiMultiplier }
            )
            .map { balance, mana in
                KoinosAccountInfo(
                    koinBalance: balance,
                    mana: mana,
                    maxMana: balance
                )
            }
            .eraseToAnyPublisher()
        }
    }
    
    func getCurrentNonce(address: String) -> AnyPublisher<KoinosAccountNonce, Error> {
        providerPublisher { provider in
            provider.getNonce(address: address)
                .map(KoinosAccountNonce.init)
                .eraseToAnyPublisher()
        }
    }
    
    func submitTransaction(transaction: KoinosProtocol.Transaction) -> AnyPublisher<KoinosTransactionEntry, Error> {
        providerPublisher { provider in
            provider.submitTransaction(transaction: transaction)
        }
    }
    
    func getRCLimit() -> AnyPublisher<Decimal, Error> {
        providerPublisher { [satoshiMultiplier] provider in
            provider.getResourceLimits()
                .map { limits in
                    let rcLimitSatoshi = Constants.MaxDiskStorageLimit * limits.diskStorageCost
                        + Constants.MaxNetworkLimit * limits.networkBandwidthCost
                        + Constants.MaxComputeLimit * limits.computeBandwidthCost
                    
                    return Decimal(rcLimitSatoshi) / satoshiMultiplier
                }
                .eraseToAnyPublisher()
        }
    }
}

private extension KoinosNetworkService {
    enum Constants {
        static let maxDiskStorageLimit: UInt64 = 118
        static let maxNetworkLimit: UInt64 = 408
        static let maxComputeLimit: UInt64 = 1_000_000
    }
}
