//
//  PolkadotJsonRpcProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 27.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya

class PolkadotJsonRpcProvider: HostProvider {
    var host: String { url.hostOrUnknown }

    private let url: URL
    private let provider: NetworkProvider<PolkadotTarget>
    
    init(url: URL, configuration: NetworkProviderConfiguration) {
        self.url = url
        provider = NetworkProvider<PolkadotTarget>(configuration: configuration)
    }
    
    func storage(key: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .storage(key: key, url: url))
    }
    
    func blockhash(_ type: PolkadotBlockhashType) -> AnyPublisher<String, Error> {
        requestPublisher(for: .blockhash(type: type, url: url))
    }
    
    func header(_ blockhash: String) -> AnyPublisher<PolkadotHeader, Error> {
        requestPublisher(for: .header(hash: blockhash, url: url))
    }
    
    func accountNextIndex(_ address: String) -> AnyPublisher<UInt64, Error> {
        requestPublisher(for: .accountNextIndex(address: address, url: url))
    }
    
    func queryInfo(_ extrinsic: String) -> AnyPublisher<PolkadotQueriedInfo, Error> {
        requestPublisher(for: .queryInfo(extrinsic: extrinsic, url: url))
    }
    
    func runtimeVersion() -> AnyPublisher<PolkadotRuntimeVersion, Error> {
        requestPublisher(for: .runtimeVersion(url: url))
    }
    
    func submitExtrinsic(_ extrinsic: String) -> AnyPublisher<String, Error> {
        requestPublisher(for: .submitExtrinsic(extrinsic: extrinsic, url: url))
    }
    
    private func requestPublisher<T: Codable>(for target: PolkadotTarget) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .map(PolkadotJsonRpcResponse<T>.self)
            .tryMap {
                if let error = $0.error?.error {
                    throw error
                }

                guard let result = $0.result else {
                    throw WalletError.empty
                }

                return result
            }
            .eraseToAnyPublisher()
    }
}
