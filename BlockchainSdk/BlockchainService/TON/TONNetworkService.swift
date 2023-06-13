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
    var exceptionHandler: ExceptionHandler?
    
    private var blockchain: Blockchain
    
    // MARK: - Init

    init(providers: [TONProvider], blockchain: Blockchain, exceptionHandler: ExceptionHandler?) {
        self.providers = providers
        self.blockchain = blockchain
        self.exceptionHandler = exceptionHandler
    }
    
    // MARK: - Implementation
    
    func getInfo(address: String) -> AnyPublisher<TONWalletInfo, Error> {
        providerPublisher { provider in
            provider
                .getInfo(address: address)
                .tryMap { [weak self] walletInfo in
                    guard let self = self else {
                        throw WalletError.empty
                    }
                    
                    guard let decimalBalance = Decimal(walletInfo.balance) else {
                        throw WalletError.failedToParseNetworkResponse
                    }
                    
                    return TONWalletInfo(
                        balance: decimalBalance / self.blockchain.decimalValue,
                        sequenceNumber: walletInfo.seqno ?? 0,
                        isAvailable: walletInfo.accountState == .active
                    )
                }
                .eraseToAnyPublisher()
        }
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
    
    func send(message: String) -> AnyPublisher<String, Error> {
        return providerPublisher { provider in
            provider
                .send(message: message)
                .map(\.hash)
                .eraseToAnyPublisher()
        }
    }
    
}
