//
//  AptosNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 29.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftyJSON

class AptosNetworkService: MultiNetworkProvider {
    // MARK: - Protperties
    
    let blockchain: Blockchain
    let providers: [AptosNetworkProvider]
    var currentProviderIndex: Int = 0
    
    // MARK: - Init
    
    init(blockchain: Blockchain, providers: [AptosNetworkProvider]) {
        self.blockchain = blockchain
        self.providers = providers
    }
    
    // MARK: - Implementation
    
    func getAccount(address: String) -> AnyPublisher<AptosAccountInfo, Error> {
        providerPublisher { provider in
            provider
                .getAccountResources(address: address)
                .tryMap { json in
                    guard let accountJson = json.arrayValue.first(where: { $0[JSONParseKey.type].stringValue == Constants.accountKeyPrefix }) else {
                        throw WalletError.failedToParseNetworkResponse
                    }
                    
                    print(accountJson)
                    
                    return AptosAccountInfo(
                        sequenceNumber: accountJson[JSONParseKey.data][JSONParseKey.sequenceNumber].uInt64Value,
                        balance: Decimal(0)
                    )
                }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Constants

private extension AptosNetworkService {
    enum Constants {
        static let accountKeyPrefix = "0x1::account::Account"
    }
}

private extension AptosNetworkService {
    enum JSONParseKey: JSONSubscriptType {
        case sequenceNumber
        case type
        case data
        
        var jsonKey: SwiftyJSON.JSONKey {
            switch self {
            case .sequenceNumber:
                return JSONKey.key("sequence_number")
            case .type:
                return JSONKey.key("type")
            case .data:
                return JSONKey.key("data")
            }
        }
    }
}
