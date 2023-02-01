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
    private(set) var host: String
    
    // MARK: - Properties
    
    /// Network provider of blockchain
    private(set) var network: NetworkProvider<TONProviderTarget>
    
    // MARK: - Implementation
    
    func getInfoWallet(address: String) -> AnyPublisher<TONWalletInfo, Error> {
        requestPublisher(for: .init(host: host, targetType: .getInfo(address: address)))
    }
    
    /// Fetch balance wallet by address
    /// - Parameter address: UserFriendly TON address wallet
    /// - Returns: String balance wallet adress or Error
    func getBalanceWallet(address: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .init(host: host, targetType: .getBalance(address: address)))
        
    }
    
    /// Get estimate sending transaction Fee
    /// - Parameter boc: Bag of Cells wallet transaction for destination
    /// - Returns: Fees or Error
    func getFee(address: String, body: String?) -> AnyPublisher<TONFee, Error> {
        requestPublisher(for: .init(host: host, targetType: .estimateFee(address: address, body: body)))
    }
    
    /// Get estimate sending transaction Fee
    /// - Parameter boc: Bag of Cells wallet transaction for destination
    /// - Returns: Fees or Error
    func getFeeWithCode(address: String, body: String?, code: String?, data: String?) -> AnyPublisher<TONFee, Error> {
        requestPublisher(
            for: .init(
                host: host,
                targetType: .estimateFeeWithCode(address: address, body: body, initCode: code, initData: data)
            )
        )
    }
    
    func send(message: String) -> AnyPublisher<TONSendBoc, Error> {
        requestPublisher(
            for: .init(host: host, targetType: .sendBoc(message: message))
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
