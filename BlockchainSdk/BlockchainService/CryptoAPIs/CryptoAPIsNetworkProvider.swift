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

/// 5991c724d463d8c887660a527809ada3317beb81
///
enum CryptoAPIsError: Error {
    case plain
}

class CryptoAPIsNetworkProvider {
    private let provider: CryptoAPIsProvider
    
    init(
        coinType: CryptoAPIsProvider.CoinType,
        apiKey: String
    ) {
        self.provider = CryptoAPIsProvider(apiKey: apiKey, coin: coinType)
    }
}

// MARK: - BitcoinNetworkProvider

extension CryptoAPIsNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool {
        return false
    }
    
    var host: String {
        CryptoAPIsProvider.host.absoluteString
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
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers.Zip(
            getBalance(address: address),
            getUnconfirmedTransactions(address: address)
        ).map { balance, transactions in
            
            return BitcoinResponse(
                balance: balance,
                hasUnconfirmed: false,
                pendingTxRefs: transactions.compactMap { $0.asPendingTransaction() } ,
                unspentOutputs: []
            )
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

extension CryptoAPIsNetworkProvider {
    func getBalance(address: String) -> AnyPublisher<Decimal, Error> {
        provider.request(endpoint: .address(address: address))
            .map(CryptoAPIsBaseResponse<CryptoAPIsAddressResponse>.self)
            .compactMap { $0.data?.item?.confirmedBalance?.amount }
            .compactMap { Decimal($0) }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getUnconfirmedTransactions(address: String) -> AnyPublisher<[CryptoAPIsTransaction], Error> {
        provider.request(endpoint: .unconfirmedTransactions(address: address))
            .map(CryptoAPIsBaseResponse<CryptoAPIsTransaction>.self)
            .compactMap { $0.data?.items }
            .eraseToAnyPublisher()
            .eraseError()
    }
}
