//
//  TONProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct TONProvider: HostProvider {
    /// Blockchain API host
    var host: String {
        node.endpoint.url.hostOrUnknown
    }
    
    /// Configuration connection node for provider
    private let node: TONNetworkNode
    
    // MARK: - Properties
    
    /// Network provider of blockchain
    private let network: NetworkProvider<TONProviderTarget>
    
    // MARK: - Init
    
    init(
        node: TONNetworkNode,
        networkConfig: NetworkProviderConfiguration
    ) {
        self.node = node
        self.network = .init(configuration: networkConfig)
    }
    
    // MARK: - Implementation
    
    /// Fetch full information about wallet address
    /// - Parameter address: UserFriendly TON address wallet
    /// - Returns: Model full information
    func getInfo(address: String) -> AnyPublisher<TONModels.Info, Error> {
        requestPublisher(for: .init(node: node, targetType: .getInfo(address: address)))
    }
    
    /// Fetch balance wallet by address
    /// - Parameter address: UserFriendly TON address wallet
    /// - Returns: String balance wallet adress or Error
    func getBalanceWallet(address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .init(node: node, targetType: .getBalance(address: address)))
        
    }
    
    /// Get estimate sending transaction Fee
    /// - Parameter address: Wallet address
    /// - Parameter body: Body of message cell TON blockchain
    /// - Returns: Fees or Error
    func getFee(address: String, body: String?) -> AnyPublisher<TONModels.Fee, Error> {
        requestPublisher(for: .init(node: node, targetType: .estimateFee(address: address, body: body)))
    }
    
    /// Send transaction data message for raw cell TON
    /// - Parameter message: String data if cell message
    /// - Returns: Result of hash transaction
    func send(message: String) -> AnyPublisher<TONModels.SendBoc, Error> {
        requestPublisher(
            for: .init(node: node, targetType: .sendBocReturnHash(message: message))
        )
    }
    
    // MARK: - Private Implementation
    
    private func requestPublisher<T: Codable>(for target: TONProviderTarget) -> AnyPublisher<T, Error> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(TONProviderResponse<T>.self, using: decoder)
            .map(\.result)
            .mapError { _ in WalletError.empty }
            .eraseToAnyPublisher()
    }
    
}
