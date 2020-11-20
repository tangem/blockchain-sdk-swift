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
    
    convenience init(isTestNet:Bool) {
        var providers = [BitcoinNetworkApi:BitcoinNetworkProvider]()
		providers[.blockchair] = BlockchairProvider(endpoint: .bitcoin)
        providers[.blockcypher] = BlockcypherProvider(coin: .btc, chain:  isTestNet ? .test3: .main)
        providers[.main] = BitcoinMainProvider()
        self.init(providers:providers, isTestNet: isTestNet)
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap {[unowned self] in self.getProvider().getInfo(address: address) }
            .tryCatch {[unowned self] error -> AnyPublisher<BitcoinResponse, Error> in
                if let moyaError = error as? MoyaError,
                    case let MoyaError.statusCode(response) = moyaError,
                    self.providers.count > 1,
                    response.statusCode > 299  {
					self.switchProvider()
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
				self.switchProvider()
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
	
	func switchProvider() {
		switch networkApi {
		case .main:
			networkApi = .blockchair
		case .blockchair:
			networkApi = .blockcypher
		default:
			networkApi = .main
		}
		print("Bitcoin network service switched to: \(networkApi)")
	}
}
