//
//  TONNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

/// Abstract layer for multi provide TON blockchain
class TONNetworkService: MultiNetworkProvider {
    
    // MARK: - Protperties
    
    let providers: [TONProvider]
    var currentProviderIndex: Int = 0
    
    private var blockchain: Blockchain
    
    // MARK: - Init
    
    init(providers: [TONProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
    
    // MARK: - Implementation
    
    func getInfo(address: String, tokens: [Token]) -> AnyPublisher<TONWalletInfo, Error> {
        Publishers.Zip(
            getWalletInfo(address: address),
            getTokensBalance(address: address, tokens: tokens)
        )
        .tryMap { [weak self] walletInfo, tokenBalances in
            guard let self else {
                throw WalletError.empty
            }
            
            guard let decimalBalance = Decimal(string: walletInfo.balance) else {
                throw WalletError.failedToParseNetworkResponse
            }
            
            return TONWalletInfo(
                balance: decimalBalance / self.blockchain.decimalValue,
                sequenceNumber: walletInfo.seqno ?? 0,
                isAvailable: walletInfo.accountState == .active,
                tokenBalances: tokenBalances
            )
        }
        .eraseToAnyPublisher()
//        getToken(address: "EQBMunNB4UlTyogGUjHTLR3vYUKuJbHUxh0-b5nQHmd6RP57", contractAddress: "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs")
//            .tryMap { result in
//                print(result)
//                throw WalletError.empty
//            }
//            .eraseToAnyPublisher()
    }
    
    func getFee(address: String, message: String) -> AnyPublisher<[Fee], Error> {
        providerPublisher { provider in
            provider
                .getFee(address: address, body: message)
                .tryMap { [weak self] fee in
                    guard let self = self else {
                        throw WalletError.empty
                    }
                    
                    /// Make rounded digits by correct for max amount Fee
                    let fee = fee.sourceFees.totalFee / self.blockchain.decimalValue
                    let roundedValue = fee.rounded(scale: 2, roundingMode: .up)
                    let feeAmount = Amount(with: self.blockchain, value: roundedValue)
                    return [Fee(feeAmount)]
                }
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Private Implementation

    func send(message: String) -> AnyPublisher<String, Error> {
        return providerPublisher { provider in
            provider
                .send(message: message)
                .map(\.hash)
                .eraseToAnyPublisher()
        }
    }
    
    private func getWalletInfo(address: String) -> AnyPublisher<TONModels.Info, Error> {
        providerPublisher { provider in
            provider
                .getInfo(address: address)
        }
    }
    
    private func getTokensBalance(address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        tokens
            .publisher
            .setFailureType(to: Error.self)
            .withWeakCaptureOf(self)
            .flatMap { networkService, token in
                networkService.getToken(address: address, token: token).map { (token, $0) }
            }
            .collect()
            .map { $0.reduce(into: [Token: Decimal]()) { $0[$1.0] = $1.1 }}
            .eraseToAnyPublisher()
    }
    
    private func getToken(address: String, token: Token) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
            provider.getWalletAddress(
                address: address,
                contractAddress: token.contractAddress
            )
            .tryMap { response in
                let reader = TupleReader(
                    items: response.stack
                )
                let address = try reader.readAddress()
                
                return address.toString(bounceable: true)
            }
            .flatMap { walletAddress in
                provider.getWalledData(walletAddress: walletAddress)
                    .tryMap { response in
                        let reader = TupleReader(
                            items: response.stack
                        )
                        
                        let amount = (try? reader.readNumber()) ?? 0
                        return Decimal(amount) / token.decimalValue
                    }
            }.eraseToAnyPublisher()
        }
    }
}
