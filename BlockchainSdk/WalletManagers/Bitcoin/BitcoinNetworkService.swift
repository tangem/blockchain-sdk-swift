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
    private let isTestNet: Bool
    private var networkApi: BitcoinNetworkApi
    private let providers: [BitcoinNetworkApi: BitcoinNetworkProvider]
    
    init(providers:[BitcoinNetworkApi: BitcoinNetworkProvider], isTestNet:Bool, defaultApi: BitcoinNetworkApi = .main) {
        self.providers = providers
        self.isTestNet = isTestNet
        self.networkApi = defaultApi
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
	
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
		getProvider().getSignatureCount(address: address)
	}
	
	private func switchProvider() {
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
