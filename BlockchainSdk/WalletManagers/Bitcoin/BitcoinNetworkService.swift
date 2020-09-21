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

class BitcoinNetworkService: BitcoinNetworkProvider {
    let isTestNet: Bool
    var networkApi: BitcoinNetworkApi = .main
    let providers: [BitcoinNetworkApi: BitcoinNetworkProvider]
    
    init(providers:[BitcoinNetworkApi: BitcoinNetworkProvider], isTestNet:Bool) {
        self.providers = providers
        self.isTestNet = isTestNet
    }
    
    convenience init(address: String, isTestNet:Bool) {
        var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
        providers[.blockcypher] = BlockcypherProvider(address: address, coin: .btc, chain:  isTestNet ? .test3: .main)
        providers[.main] = BitcoinMainProvider(address: address)
        self.init(providers:providers, isTestNet: isTestNet)
    }
    
    func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] in self.getProvider().getInfo() }
            .tryCatch {[unowned self] error -> AnyPublisher<BitcoinResponse, Error> in
                if let moyaError = error as? MoyaError,
                    case let MoyaError.statusCode(response) = moyaError,
                    self.providers.count > 1,
                    response.statusCode > 299  {
                    if self.networkApi == .main {
                        self.networkApi = .blockcypher
                    }
                }
                
                throw error
        }
        .retry(1)
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func getFee() -> AnyPublisher<BtcFee, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] _ -> AnyPublisher<BtcFee, Error> in
                self.getProvider().getFee()
            }
            .tryCatch {[unowned self] error -> AnyPublisher<BtcFee, Error> in
                if self.networkApi == .main {
                    self.networkApi = .blockcypher
                }
                throw error
        }
        .retry(1)
        .eraseToAnyPublisher()
    }
    
    @available(iOS 13.0, *)
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap{[unowned self] in self.getProvider().send(transaction: transaction) }
            .eraseToAnyPublisher()
    }
    
    func getProvider() -> BitcoinNetworkProvider {
        if providers.count == 1 {
            return providers.first!.value
        }
        
        return isTestNet ? providers[.blockcypher]!: providers[networkApi]!
    }
}
