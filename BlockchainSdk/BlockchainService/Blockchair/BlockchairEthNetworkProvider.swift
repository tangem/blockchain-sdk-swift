//
//  BlockchairEthNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 05/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import SwiftyJSON

class BlockchairEthNetworkProvider {
    let provider = MoyaProvider<BlockchairTarget>()
    
    private let endpoint: BlockchairEndpoint
    private let apiKey: String
    
    init(endpoint: BlockchairEndpoint, apiKey: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
    }
    
    func findErc20Tokens(address: String) -> AnyPublisher<[BlockchairToken], Error> {
        publisher(for: .findErc20Tokens(address: address, endpoint: endpoint))
            .tryMap {[weak self] json -> [BlockchairToken] in
                guard let self = self else { throw WalletError.empty }
                
                let addr = self.mapAddressBlock(address, json: json)
                let tokensObject = addr["layer_2"]["erc_20"]
                let tokensData = try tokensObject.rawData()
                let tokens = try JSONDecoder().decode([BlockchairToken].self, from: tokensData)
                return tokens
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func publisher(for type: BlockchairTarget.BlockchairTargetType) -> AnyPublisher<JSON, MoyaError> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap { [weak self] _ -> AnyPublisher<JSON, Error> in
                guard let self = self else {
                    return .emptyFail
                }
                
                return self.provider
                    .requestPublisher(BlockchairTarget(type: type, apiKey: nil))
                    .filterSuccessfulStatusAndRedirectCodes()
                    .mapSwiftyJSON()
                    .eraseError()
                    .catch { [weak self] error -> AnyPublisher<JSON, Error> in
                        guard let self = self else {
                            return .emptyFail
                        }
                        
                        if self.paymentRequired(error) {
                            return self.provider
                                .requestPublisher(BlockchairTarget(type: type, apiKey: self.apiKey))
                                .filterSuccessfulStatusAndRedirectCodes()
                                .mapSwiftyJSON()
                                .eraseError()
                        } else {
                            return Fail(error: error).eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .mapError {
                return MoyaError.underlying($0, nil)
            }
            .eraseToAnyPublisher()
    }
    
    private func paymentRequired(_ error: Error) -> Bool {
        if case let MoyaError.statusCode(response) = error, response.statusCode == 402 {
            return true
        } else {
            return false
        }
    }
}

extension BlockchairEthNetworkProvider: BlockchairAddressBlockMapper {}
