//
//  ICPNetworkService.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import IcpKit
import TangemSdk

final class ICPNetworkService: MultiNetworkProvider {
    
    // MARK: - Protperties
    
    let providers: [ICPNetworkProvider]
    var currentProviderIndex: Int = 0
    
    private var blockchain: Blockchain
    
    // MARK: - Init
    
    init(providers: [ICPNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
    
    func getBalance(address: String) -> AnyPublisher<Decimal, Error> {
        guard let balanceRequestData = try? makeBalanceRequestData(address: address) else {
            return .anyFail(error: WalletError.empty).eraseToAnyPublisher()
        }
        return providerPublisher { [blockchain] provider in
            provider
                .getBalance(data: balanceRequestData)
                .map { result in
                    result / blockchain.decimalValue
                }
                .eraseToAnyPublisher()
        }
    }
    
    func send(data: Data) -> AnyPublisher<Void, Error> {
        providerPublisher { provider in
            provider
                .send(data: data)
        }
    }
    
    func readState(data: Data, paths: [ICPStateTreePath]) -> AnyPublisher<UInt64?, Error> {
        providerPublisher { provider in
            provider
                .readState(data: data, paths: paths)
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Private implementation
    
    private func makeBalanceRequestData(address: String) throws -> Data {
        let envelope = ICPRequestEnvelope(
            content: ICPRequestBuilder.makeCallRequestContent(
                method: .balance(account: Data(hex: address)),
                requestType: .query,
                date: Date(),
                nonce: try CryptoUtils.icpNonce()
            )
        )
        return try envelope.cborEncoded()
    }
}

extension CryptoUtils {
    static func icpNonce() throws -> Data {
        try generateRandomBytes(count: 32)
    }
}
