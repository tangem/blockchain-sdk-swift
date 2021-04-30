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

class BitcoinNetworkService: MultiNetworkProvider<BitcoinNetworkProvider> {
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
                .mapError {[unowned self] in self.handleError($0)}
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        providerPublisher{
            $0.getInfo(address: address)
                .mapError {[unowned self] in self.handleError($0)}
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
    
    func getFee() -> AnyPublisher<BtcFee, Error> {
        Publishers.MergeMany(providers.map { $0.getFee() })
            .collect()
            .mapError { [unowned self] in self.handleError($0) }
            .retry(2)
            .map { feeList -> BtcFee in
                var min: Decimal = 0
                var norm: Decimal = 0
                var priority: Decimal = 0
                feeList.forEach {
                    min = max($0.minimalSatoshiPerByte, min)
                    norm = max($0.normalSatoshiPerByte, norm)
                    priority = max($0.prioritySatoshiPerByte, priority)
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
    
    private func handleError(_ error: Error) -> Error {
        if let moyaError = error as? MoyaError,
           case let MoyaError.statusCode(response) = moyaError,
           self.providers.count > 1,
           response.statusCode > 299  {
            switchProvider()
        }
        
        return error
    }
	
	private func switchProvider() {
		switch networkApi {
		case .main:
			networkApi = .blockchair
		case .blockchair:
			networkApi = .blockcypher
        case .blockcypher:
            networkApi = .blockchair
		}
		print("Bitcoin network service switched to: \(networkApi)")
	}
	
}
