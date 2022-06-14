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
    private let provider: CryptoAPIsMoyaProvider
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    init(
        coinType: CryptoAPIsMoyaProvider.CoinType,
        apiKey: String
    ) {
        self.provider = CryptoAPIsMoyaProvider(apiKey: apiKey, coin: coinType)
    }
}

// MARK: - BitcoinNetworkProvider

extension CryptoAPIsNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool {
        return false
    }
    
    var host: String {
        CryptoAPIsMoyaProvider.host.absoluteString
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
        Publishers.CombineLatest3(
            getBalance(address: address),
            getUnconfirmedTransactions(address: address),
            getUnspentOutputs(address: address)
        ).map { balance, transactions, unspentOutputs in
            return BitcoinResponse(
                balance: balance,
                hasUnconfirmed: transactions.isEmpty,
                pendingTxRefs: transactions.compactMap { $0.asPendingTransaction() } ,
                unspentOutputs: unspentOutputs.compactMap { $0.asBitcoinUnspentOutput() }
            )
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CryptoAPIsNetworkProvider {
    func getBalance(address: String) -> AnyPublisher<Decimal, Error> {
        provider.request(endpoint: .address(address: address))
            .map(CryptoAPIsBase<CryptoAPIsBaseItem<CryptoAPIsAddress>>.self, using: decoder)
            .print()
            .compactMap { $0.data?.item?.confirmedBalance?.amount }
            .compactMap { Decimal($0) }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getUnconfirmedTransactions(address: String) -> AnyPublisher<[CryptoAPIsTransaction], Error> {
        provider.request(endpoint: .unconfirmedTransactions(address: address))
            .map(CryptoAPIsBase<CryptoAPIsBaseItems<CryptoAPIsTransaction>>.self, using: decoder)
            .print()
            .compactMap { $0.data?.items }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getUnspentOutputs(address: String) -> AnyPublisher<[CryptoAPIsUnspentOutputs], Error> {
        provider.request(endpoint: .unspentOutputs(address: address))
            .map(CryptoAPIsBase<CryptoAPIsBaseItems<CryptoAPIsUnspentOutputs>>.self, using: decoder)
            .print()
            .compactMap { $0.data?.items }
            .eraseToAnyPublisher()
            .eraseError()
    }
}
