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
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        push(transaction: transaction)
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        sendTransaction(hex: transaction)
            .map { $0.transactionId }
            .eraseToAnyPublisher()
    }
    
    // TODO: Research will be continue
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        Result.failure(CryptoAPIsError.unimplemented).publisher.eraseToAnyPublisher()
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers.CombineLatest3(
            getBalance(address: address),
            getUnconfirmedTransactions(address: address),
            getBitcoinUnspentOutput(address: address)
        ).map { balance, transactions, unspentOutputs in
            return BitcoinResponse(
                balance: balance,
                hasUnconfirmed: transactions.isEmpty,
                pendingTxRefs: transactions.compactMap { $0.asPendingTransaction() } ,
                unspentOutputs: unspentOutputs
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
    
    func getConfirmedTransactions(address: String) -> AnyPublisher<[CryptoAPIsTransaction], Error> {
        provider.request(endpoint: .confirmedTransactions(address: address))
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
    
    func getBitcoinUnspentOutput(address: String) -> AnyPublisher<[BitcoinUnspentOutput], Error> {
        Publishers.CombineLatest(
            getUnspentOutputs(address: address),
            getConfirmedTransactions(address: address)
        ).map { outputs, transactions -> [BitcoinUnspentOutput] in
            outputs.compactMap { output in
                guard let tx = transactions.first(where: { $0.transactionId == output.transactionId }),
                      let amount = Double(output.amount),
                      let out = tx.blockchainSpecific.vout.first else {
                    return nil
                }
                
                let satoshi = Decimal(amount).convertToSatoshi(coinRate: pow(10, 8))
                
                return BitcoinUnspentOutput(transactionHash: tx.transactionHash,
                                            outputIndex: output.index,
                                            amount: UInt64(satoshi),
                                            outputScript: out.scriptPubKey.hex)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func sendTransaction(hex: String) -> AnyPublisher<CryptoAPIsPushTxResponse, Error> {
        provider.request(endpoint: .push(hex: hex))
            .map(CryptoAPIsBase<CryptoAPIsBaseItem<CryptoAPIsPushTxResponse>>.self)
            .map { $0.data.item }
            .eraseToAnyPublisher()
            .eraseError()
    }
}

extension Decimal {
    func convertToSatoshi(coinRate: Decimal) -> Int {
        let coinValue: Decimal = self * coinRate

        let handler = NSDecimalNumberHandler(roundingMode: .plain,
                                             scale: 0,
                                             raiseOnExactness: false,
                                             raiseOnOverflow: false,
                                             raiseOnUnderflow: false,
                                             raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
    }
}
