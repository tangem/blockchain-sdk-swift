//
//  CryptoAPIsNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 10.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

enum CryptoAPIsError: Error {
    case plain
}

class CryptoAPIsNetworkProvider {
    let provider = MoyaProvider<CryptoAPIsTarget>()
    

}

// MARK: - Private

extension CryptoAPIsNetworkProvider {
    func getBalance(address: String) -> AnyPublisher<CryptoAPIsAddressResponse, Error> {
        let target = CryptoAPIsTarget(apiKey: "5991c724d463d8c887660a527809ada3317beb81",
                                      target: .address(address: address, coin: .dash))
        
        return provider.requestPublisher(target)
            .map(CryptoAPIsBaseResponse.self)
            .compactMap { $0.data?.item }
            .eraseToAnyPublisher()
            .eraseError()
    }
}

// MARK: - BitcoinNetworkProvider

extension CryptoAPIsNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool {
        return false
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        Result.failure(CryptoAPIsError.plain).publisher.eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        Result.failure(CryptoAPIsError.plain).publisher.eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        Result.failure(CryptoAPIsError.plain).publisher.eraseToAnyPublisher()
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        Result.failure(CryptoAPIsError.plain).publisher.eraseToAnyPublisher()
    }
    
    var host: String {
        CryptoAPIsTarget.host.absoluteString
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        getBalance(address: address)
            .map { response in
                let balance = Decimal(response.confirmedBalance?.amount ?? "") ?? 0
                return BitcoinResponse(
                    balance: balance,
                    hasUnconfirmed: false,
                    pendingTxRefs: [],
                    unspentOutputs: []
                )
            }
            .eraseToAnyPublisher()
    }
}
