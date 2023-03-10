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
    
    // MARK: - HostProvider
    
    /// Blockchain API host
    var host: String {
        node.endpoint.url.hostOrUnknown
    }
    
    /// Configuration connection node for provider
    private(set) var node: TONNetworkNode
    
    // MARK: - Properties
    
    /// Network provider of blockchain
    private(set) var network: NetworkProvider<TONProviderTarget>
    
    // MARK: - Init
    
    init?(
        endpointType: TONEndpointType,
        config: BlockchainSdkConfig,
        network: NetworkProvider<TONProviderTarget>,
        isTestnet: Bool
    ) {
        let apiKeyValue: String
        
        switch endpointType {
        case .toncenter:
            apiKeyValue = config.tonCenterApiKey
        case .getblock:
            apiKeyValue = config.getBlockApiKey
        case .nownodes:
            apiKeyValue = config.nowNodesApiKey
        }
        
        guard let node = TONNetworkNode(
            apiKeyValue: apiKeyValue,
            endpointType: endpointType,
            isTestnet: isTestnet
        ) else {
            return nil
        }
        
        self.node = node
        self.network = network
    }
    
    // MARK: - Implementation
    
    func getInfo(address: String) -> AnyPublisher<TONProviderContent.Info, Error> {
        requestPublisher(for: .init(node: node, targetType: .getInfo(address: address)))
    }
    
    /// Fetch balance wallet by address
    /// - Parameter address: UserFriendly TON address wallet
    /// - Returns: String balance wallet adress or Error
    func getBalanceWallet(address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .init(node: node, targetType: .getBalance(address: address)))
        
    }
    
    /// Get estimate sending transaction Fee
    /// - Parameter boc: Bag of Cells wallet transaction for destination
    /// - Returns: Fees or Error
    func getFee(address: String, body: String?) -> AnyPublisher<TONProviderContent.Fee, Error> {
        requestPublisher(for: .init(node: node, targetType: .estimateFee(address: address, body: body)))
    }
    
    /// Get estimate sending transaction Fee
    /// - Parameter boc: Bag of Cells wallet transaction for destination
    /// - Returns: Fees or Error
    func getFeeWithCode(address: String, body: String?, code: String?, data: String?) -> AnyPublisher<TONProviderContent.Fee, Error> {
        requestPublisher(
            for: .init(
                node: node,
                targetType: .estimateFeeWithCode(address: address, body: body, initCode: code, initData: data)
            )
        )
    }
    
    func send(message: String) -> AnyPublisher<TONProviderContent.SendBoc, Error> {
        requestPublisher(
            for: .init(node: node, targetType: .sendBocReturnHash(message: message))
        )
    }
    
    // MARK: - Private Implementation
    
    private func requestPublisher<T: Codable>(for target: TONProviderTarget) -> AnyPublisher<T, Error> {
        return network.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(TONProviderResponse<T>.self)
            .tryMap { $0.result }
            .eraseToAnyPublisher()
    }
    
}
