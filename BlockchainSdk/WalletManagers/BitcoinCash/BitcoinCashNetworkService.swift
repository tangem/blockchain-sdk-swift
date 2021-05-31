//
//  BitcoinCashNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine
import TangemSdk

class BitcoinCashNetworkService {
    private let provider: BlockchairNetworkProvider
    
    var currentHost: String {
        provider.host
    }

    init(provider: BlockchairNetworkProvider) {
        self.provider = provider
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        return provider.getInfo(address: address)
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        return provider.getFee()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return provider.send(transaction: transaction)
    }
	
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
		provider.getSignatureCount(address: address)
	}
}
