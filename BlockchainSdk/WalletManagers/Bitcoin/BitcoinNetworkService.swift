//
//  BitcoinNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk
import Alamofire

class BitcoinNetworkService: MultiNetworkProvider<BitcoinNetworkProvider>, BitcoinNetworkProvider {
    private let isTestNet: Bool
    private var networkApi: BitcoinNetworkApi
    
    init(providers: [BitcoinNetworkProvider], isTestNet: Bool, defaultApi: BitcoinNetworkApi = .main) {
        self.isTestNet = isTestNet
        self.networkApi = defaultApi
        super.init(providers: providers)
    }
    
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        providerPublisher {
            $0.getInfo(addresses: addresses)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        providerPublisher{
            $0.getInfo(address: address)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
        Publishers.MergeMany(providers.map {
            $0.getFee()
                .retry(2)
                .replaceError(with: BtcFee(minimalSatoshiPerByte: 0, normalSatoshiPerByte: 0, prioritySatoshiPerByte: 0))
                .eraseToAnyPublisher()
        })
        .collect()
        .tryMap { feeList -> BtcFee in
            var min: Decimal = 0
            var norm: Decimal = 0
            var priority: Decimal = 0
            feeList.forEach {
                min = max($0.minimalSatoshiPerByte, min)
                norm = max($0.normalSatoshiPerByte, norm)
                priority = max($0.prioritySatoshiPerByte, priority)
            }
            
            guard min > 0 , norm > 0, priority > 0 else {
                throw BlockchainSdkError.failedToLoadFee
            }
            return BtcFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: norm, prioritySatoshiPerByte: priority)
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.send(transaction: transaction)
        }
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        providerPublisher {
            $0.getSignatureCount(address: address)
        }
    }
    
}
