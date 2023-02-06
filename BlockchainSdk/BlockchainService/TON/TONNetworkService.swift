//
//  TONNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

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
    
    func getInfoWallet(address: String) -> AnyPublisher<TONWalletInfo, Error> {
        providerPublisher { provider in
            provider
                .getInfoWallet(address: address)
                .tryMap { [weak self] walletInfo in
                    guard let self = self else {
                        throw WalletError.empty
                    }
                    
                    guard let decimalBalance = Decimal(walletInfo.balance) else {
                        throw WalletError.failedToParseNetworkResponse
                    }
                    
                    return TONWalletInfo(
                        balance: decimalBalance / self.blockchain.decimalValue,
                        seqno: walletInfo.seqno ?? 0,
                        isAvailable: walletInfo.account_state == .active
                    )
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getFee(message: TONExternalMessage) -> AnyPublisher<[Amount], Error> {
        providerPublisher { provider in
            if message.code != nil {
                return provider
                    .getFeeWithCode(
                        address: message.address.toString(),
                        body: try? Data(optional: message.body.toBoc(false))?.base64EncodedString(),
                        code: try? Data(optional: message.code?.toBoc(false))?.base64EncodedString(),
                        data: try? Data(optional: message.data?.toBoc(false))?.base64EncodedString()
                    )
                    .tryMap { [weak self] fee in
                        guard let self = self else {
                            throw WalletError.empty
                        }
                        
                        
                        return [
                            .init(with: .ton(testnet: self.blockchain.isTestnet), value: (fee.source_fees.allFee / self.blockchain.decimalValue))
                        ]
                    }
                    .eraseToAnyPublisher()
            } else {
                return provider
                    .getFee(
                        address: message.address.toString(),
                        body: try? Data(message.message.toBoc(false)).base64EncodedString()
                    )
                    .tryMap { [weak self] fee in
                        guard let self = self else {
                            throw WalletError.empty
                        }
                        
                        print(fee)
                        
                        return [
                            .init(with: .ton(testnet: self.blockchain.isTestnet), value: (fee.source_fees.allFee / self.blockchain.decimalValue))
                        ]
                    }
                    .eraseToAnyPublisher()
            }
        }
    }
    
    func send(message: TONExternalMessage) -> AnyPublisher<String, Error> {
        return providerPublisher { provider in
            provider
                .send(message: (try? Data(message.message.toBoc(false)))?.base64EncodedString() ?? "")
                .tryMap { result in
                    return result.hash
                }
                .eraseToAnyPublisher()
        }
    }
    
}
