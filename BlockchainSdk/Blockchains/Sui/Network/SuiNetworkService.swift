//
// SuiNetworkService.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 30.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletCore

final class SuiNetworkService: MultiNetworkProvider {
    let providers: [SuiNetworkProvider]
    var currentProviderIndex: Int 
    let balanceFetcher = SuiBalanceFetcher()
    
    public init(providers: [SuiNetworkProvider]) {
        self.providers = providers
        self.currentProviderIndex = 0
    }
    
    public func getBalance(address: String, coin: Sui.CoinType, cursor: String?) -> AnyPublisher<[SuiGetCoins.Coin], Error> {
        balanceFetcher
            .requestPublisher(with: { [weak self] nextAddress, nextCoin, nextCursor in
            guard let self else {
                return .anyFail(error: NetworkServiceError.notAvailable)
            }
            return self.providerPublisher { provider in
                provider
                    .getBalance(address: nextAddress, coin: nextCoin, cursor: nextCursor)
            }
        })
        .fetchBalanceRequestPublisher(address: address, coin: coin.string, cursor: cursor)
    }
    
    public func getReferenceGasPrice() -> AnyPublisher<SuiReferenceGasPrice, Error> {
        providerPublisher { provider in
            provider
                .getReferenceGasPrice()
        }
    }
    
    public func dryTransaction(transaction raw: String) -> AnyPublisher<SuiInspectTransaction, Error> {
        providerPublisher { provider in
            provider
                .dryRunTransaction(transaction: raw)
        }
    }
    
    public func devInspectTransaction(sender: String, transaction raw: String, referencedGasPrice: String?) -> AnyPublisher<SuiInspectTransaction, Error> {
        providerPublisher { provider in
            provider
                .devInspectTransaction(sender: sender, transaction: raw, referenceGasPrice: referencedGasPrice)
            
        }
    }
    
    public func sendTransaction(transaction raw: String, signature: String) -> AnyPublisher<SuiExecuteTransaction, Error> {
        providerPublisher { provider in
            provider
                .sendTransaction(transaction: raw, signature: signature)
        }
    }
    
}
