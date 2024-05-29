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
    private let decimalCount = Decimal(Blockchain.koinos(testnet: false).decimalCount)
    
    init(providers: [KoinosNetworkProvider]) {
        self.providers = providers
    }
    
    func getInfo(address: String) -> AnyPublisher<KoinosAccountInfo, Error> {
        providerPublisher { [decimalCount] provider in
            let balanceResult: AnyPublisher<UInt64, Error>
            let manaResult: AnyPublisher<UInt64, Error>
            
            do {
                balanceResult = try provider.getKoinBalance(address: address)
                manaResult = provider.getRC(address: address)
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
            
            return Publishers.Zip(
                balanceResult.map { Decimal($0) / decimalCount },
                manaResult.map { Decimal($0) / decimalCount }
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
    
    func getRCLimit() -> AnyPublisher<Decimal, Error> /* TODO: [KOINOS] BigDecimal? */ {
        providerPublisher { [decimalCount] provider in
            provider.getResourceLimits()
                .map { limits in
                    let rcLimitSatoshi = KoinosNetworkServiceConstants.MaxDiskStorageLimit * limits.diskStorageCost
                        + KoinosNetworkServiceConstants.MaxNetworkLimit * limits.networkBandwidthCost
                        + KoinosNetworkServiceConstants.MaxComputeLimit * limits.computeBandwidthCost
                    
                    return Decimal(rcLimitSatoshi) / decimalCount
                }
                .eraseToAnyPublisher()
        }
    }
}

private enum KoinosNetworkServiceConstants {
    static let MaxDiskStorageLimit: UInt64 = 118
    static let MaxNetworkLimit: UInt64 = 408
    static let MaxComputeLimit: UInt64 = 1_000_000
}
