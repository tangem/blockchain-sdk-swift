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
        publisher(for: .findErc20Tokens(address: address, endpoint: endpoint, apiKey: apiKey))
            .tryMap { json -> [BlockchairToken] in
                let addr = self.mapAddressBlock(address, json: json)
                let tokensObject = addr["layer_2"]["erc_20"]
                let tokensData = try tokensObject.rawData()
                let tokens = try JSONDecoder().decode([BlockchairToken].self, from: tokensData)
                return tokens
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    private func publisher(for target: BlockchairTarget) -> AnyPublisher<JSON, MoyaError> {
        provider
            .requestPublisher(target)
            .filterSuccessfulStatusAndRedirectCodes()
            .mapSwiftyJSON()
    }
}

extension BlockchairEthNetworkProvider: BlockchairAddressBlockMapper {}
