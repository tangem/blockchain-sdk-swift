//
//  BlockscoutNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct BlockscoutNetworkProvider {
    private let networkProvider: NetworkProvider<BlockscoutTarget>
    private let mapper: BlockscoutResponseMapper
    
    init(configuration: NetworkProviderConfiguration, mapper: BlockscoutResponseMapper) {
        self.networkProvider = NetworkProvider(configuration: configuration)
        self.mapper = mapper
    }
    
    func loadTransactionHistory(address: String) -> AnyPublisher<[TransactionRecord], Error> {
        return networkProvider.requestPublisher(.tokenTransfersHistory(address: address, contractAddress: nil))
            .filterSuccessfulStatusAndRedirectCodes()
            .tryMap { response in
                let jsonDecoder = JSONDecoder()
                // When error occurs on the API side it returns null in the result field and puts error message
                // to the message. So we need to check if result is not nil, if so - return result, otherwise
                // throw received in `message` error
                let decodedResponse = try jsonDecoder.decode(BlockscoutResponse<[BlockscoutTransaction]?>.self, from: response.data)
                
                if let result = decodedResponse.result {
                    let records = result.compactMap { self.mapper.mapToTransactionRecord($0) }
                    return records
                }
                
                throw decodedResponse.message
            }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
