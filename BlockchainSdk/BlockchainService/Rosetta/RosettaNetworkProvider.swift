//
//  RosettaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Moya
import SwiftCBOR

class RosettaNetworkProvider: CardanoNetworkProvider {
    
    private let provider: MoyaProvider<RosettaTarget> = .init()
    private let baseUrl: RosettaUrl
    
    var host: String {
        URL(string: baseUrl.rawValue)!.hostOrUnknown
    }
    
    init(baseUrl: RosettaUrl) {
        self.baseUrl = baseUrl
    }
    
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error> {
        .multiAddressPublisher(addresses: addresses, requestFactory: {[weak self] address in
            guard let self = self else { return .emptyFail }
            
            let balancesPublisher = self.provider
                .requestPublisher(.address(baseUrl: self.baseUrl,
                                           addressBody: RosettaAddressBody(networkIdentifier: .mainNet,
                                                                           accountIdentifier: RosettaAccountIdentifier(address: address))))
                .mapNotEmptyString()
                .tryMap {(response: String) -> RosettaBalanceResponse in
                    guard let data = response.data(using: .utf8) else {
                        throw WalletError.failedToParseNetworkResponse
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    return try decoder.decode(RosettaBalanceResponse.self, from: data)
                }
                .eraseToAnyPublisher()
            
            let coinsPublisher = self.provider
                .requestPublisher(.coins(baseUrl: self.baseUrl,
                                         addressBody: RosettaAddressBody(networkIdentifier: .mainNet,
                                                                         accountIdentifier: RosettaAccountIdentifier(address: address))))
                .mapNotEmptyString()
                .tryMap {(response: String) -> RosettaCoinsResponse in
                    guard let data = response.data(using: .utf8) else {
                        throw WalletError.failedToParseNetworkResponse
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    return try decoder.decode(RosettaCoinsResponse.self, from: data)
                }
                .eraseToAnyPublisher()
            
            return Publishers.Zip(balancesPublisher, coinsPublisher)
                .map {($0, $1, address)}
                .eraseToAnyPublisher()
        })
        .map { (responses: [(RosettaBalanceResponse, RosettaCoinsResponse, String)]) -> CardanoAddressResponse in
            let cardanoCurrencySymbol = "ADA"
            var balance = Decimal(0)
            var unspentOutputs = [CardanoUnspentOutput]()
            
            responses.forEach { (balanceResponse, coinsResponse, address) in
                coinsResponse.coins?.forEach { coin in
                    if coin.amount?.currency?.symbol == cardanoCurrencySymbol,
                       let splittedIdentifier = coin.coinIdentifier?.identifier?.split(separator: ":"),
                       splittedIdentifier.count == 2,
                       let index = Int(splittedIdentifier[1]) {
                        unspentOutputs.append(CardanoUnspentOutput(address: address,
                                                                   amount: coin.amount?.valueDecimal ?? 0,
                                                                   outputIndex: index,
                                                                   transactionHash: String(splittedIdentifier[0])))
                    }
                }
                balanceResponse.balances?.forEach { b in
                    if b.currency?.symbol == cardanoCurrencySymbol {
                        balance += b.valueDecimal ?? 0
                    }
                }
            }
            
            balance = balance / Blockchain.cardano(shelley: false).decimalValue
            
            return CardanoAddressResponse(balance: balance,
                                          recentTransactionsHashes: [],
                                          unspentOutputs: unspentOutputs)
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        let txHex: String = CBOR.array(
            [CBOR.utf8String(transaction.toHexString())]
        ).encode().toHexString()
        
        return provider.requestPublisher(.submitTransaction(baseUrl: baseUrl,
                                                            submitBody: RosettaSubmitBody(networkIdentifier: .mainNet,
                                                                                          signedTransaction: txHex)))
            .mapNotEmptyString()
            .tryMap{(resp: String) -> String in
                guard let data = resp.data(using: .utf8) else {
                    throw WalletError.failedToParseNetworkResponse
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let submitResponse = try decoder.decode(RosettaSubmitResponse.self, from: data)
                return submitResponse.transactionIdentifier.hash ?? ""
            }
            .eraseToAnyPublisher()
    }
}
