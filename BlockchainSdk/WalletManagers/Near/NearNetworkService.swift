//
//  NearNetworkService.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 04.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import BigInt

@available(iOS 13, *)
class NearNetworkService {
    let provider: MoyaProvider = MoyaProvider<NearTarget>()
    let blockchain: Blockchain
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
    
    func gasPrice() -> AnyPublisher<Int, Error> {
        provider
            .requestPublisher(.init(endpoint: .gasPrice(isTestnet: blockchain.isTestnet)))
            .map(NearGasPriceResponse.self, using: decoder)
            .tryMap({ response in
                guard let price = Int(response.result.gasPrice) else {
                    throw WalletError.empty
                }
                return price
            })
            .eraseToAnyPublisher()
    }
}
