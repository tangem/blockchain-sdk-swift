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
    case unimplemented
}

class CryptoAPIsNetworkProvider {
    private let provider: CryptoAPIsMoyaProvider
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    init(coinType: CryptoAPIsMoyaProvider.CoinType, apiKey: String) {
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
        getFeeRecommendations()
            .compactMap { fee -> BitcoinFee? in
                guard let minimal = Decimal(fee.slow),
                      let normal = Decimal(fee.standard),
                      let priority = Decimal(fee.fast) else {
                    return nil
                }

                return BitcoinFee(
                    minimalSatoshiPerByte: minimal,
                    normalSatoshiPerByte: normal,
                    prioritySatoshiPerByte: priority
                )
            }
            .eraseToAnyPublisher()
    }
    
    // TODO: Research will be continue
    func send(transaction: String) -> AnyPublisher<String, Error> {
        Result.failure(CryptoAPIsError.unimplemented).publisher.eraseToAnyPublisher()
    }
    
    // TODO: Research will be continue
    func push(transaction: String) -> AnyPublisher<String, Error> {
        Result.failure(CryptoAPIsError.unimplemented).publisher.eraseToAnyPublisher()
    }
    
    // TODO: Research will be continue
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        Result.failure(CryptoAPIsError.unimplemented).publisher.eraseToAnyPublisher()
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
            .compactMap { Decimal($0.data.item.confirmedBalance.amount) }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getUnconfirmedTransactions(address: String) -> AnyPublisher<[CryptoAPIsTransaction], Error> {
        provider.request(endpoint: .unconfirmedTransactions(address: address))
            .map(CryptoAPIsBase<CryptoAPIsBaseItems<CryptoAPIsTransaction>>.self, using: decoder)
            .map { $0.data.items }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getUnspentOutputs(address: String) -> AnyPublisher<[CryptoAPIsUnspentOutputs], Error> {
        provider.request(endpoint: .unspentOutputs(address: address))
            .map(CryptoAPIsBase<CryptoAPIsBaseItems<CryptoAPIsUnspentOutputs>>.self, using: decoder)
            .map { $0.data.items }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getFeeRecommendations() -> AnyPublisher<CryptoAPIsFee, Error> {
        provider.request(endpoint: .fee)
            .map(CryptoAPIsBase<CryptoAPIsBaseItem<CryptoAPIsFee>>.self, using: decoder)
            .map { $0.data.item }
            .eraseToAnyPublisher()
            .eraseError()
    }
}
