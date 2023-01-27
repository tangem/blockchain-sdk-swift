//
//  TONProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct TONNetworkProvider: HostProvider {
    
    // MARK: - HostProvider
    
    /// Blockchain API host
    private(set) var host: String
    
    // MARK: - Properties
    
    /// Network provider of blockchain
    private(set) var provider: NetworkProvider<TONProvirerTarget>
    
    /// Blockchain model inject from factory
    private(set) var blockchain: Blockchain
    
    // MARK: - Implementation
    
    /// Fetch balance wallet by address
    /// - Parameter address: UserFriendly TON address wallet
    /// - Returns: Balance wallet adress or Error
    func getBalanceWallet(address: String) -> AnyPublisher<Decimal, Error> {
        provider.requestPublisher(
            .init(
                host: host,
                targetType: .getBalance(address: address)
            )
        )
        .filterSuccessfulStatusAndRedirectCodes()
        .map(TONProviderResponse<String>.self)
        .tryMap { response in
            guard let result = Decimal(response.result) else {
                throw WalletError.failedToParseNetworkResponse
            }
            return result / blockchain.decimalValue
        }
        .eraseToAnyPublisher()
        
    }
    
    /// Get sequence number transaction in chain
    /// - Parameter address: Wallet address
    /// - Returns: Integer number of sequence
    func getSeqno(by address: String) -> AnyPublisher<Int, Error> {
        provider.requestPublisher(
            .init(
                host: host,
                targetType: .seqno
            )
        )
        .filterSuccessfulStatusAndRedirectCodes()
        .map(TONProviderResponse<Int>.self)
        .tryMap { response in
            throw WalletError.failedToParseNetworkResponse
        }
        .eraseToAnyPublisher()
    }
    
    /// Get estimate sending transaction Fee
    /// - Parameter boc: Bag of Cells wallet transaction for destination
    /// - Returns: Fees or Error
    func getFee(by boc: String) -> AnyPublisher<[Amount], Error> {
        provider.requestPublisher(
            .init(
                host: host,
                targetType: .estimateFee(boc: "")
            )
        )
        .filterSuccessfulStatusAndRedirectCodes()
        .map(TONProviderResponse<String>.self)
        .tryMap { response in
            throw WalletError.failedToParseNetworkResponse
        }
        .eraseToAnyPublisher()
    }
    
}
