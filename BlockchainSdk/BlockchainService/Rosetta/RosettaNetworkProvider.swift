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
    var host: String {
        URL(string: baseUrl.url)!.hostOrUnknown
    }
    
    private let provider: NetworkProvider<RosettaTarget>
    private let baseUrl: RosettaUrl
    private let cardanoCurrencySymbol: String = Blockchain.cardano(shelley: false).currencySymbol
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    init(baseUrl: RosettaUrl, configuration: NetworkProviderConfiguration) {
        self.baseUrl = baseUrl
        provider = NetworkProvider<RosettaTarget>(configuration: configuration)
    }
    
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error> {
        typealias Response = (balance: RosettaBalanceResponse, coins: RosettaCoinsResponse, address: String)
        
        return AnyPublisher<Response, Error>.multiAddressPublisher(addresses: addresses) { [weak self] address -> AnyPublisher<Response, Error> in
            guard let self else {
                return .emptyFail
            }
            
            return Publishers.Zip(balancePublisher(for: address), coinsPublisher(for: address))
                .map { (balance: $0, coins: $1, address: address) }
                .eraseToAnyPublisher()
        }
        .tryMap { [weak self] responses -> CardanoAddressResponse in
            guard let self else {
                throw WalletError.empty
            }
            
            let unspentOutputs = responses.flatMap {
                self.mapToCardanoUnspentOutput(response: $0.coins, address: $0.address)
            }
            
            let balances = responses.flatMap { $0.balance.balances ?? [] }
            var balance: Decimal = balances.reduce(0) { result, balance in
                // Calculate only coin balances
                guard balance.currency?.symbol == self.cardanoCurrencySymbol,
                      let value = Decimal(balance.value) else {
                    return result
                }
                
                return result + value
            }
            
            balance = balance / Blockchain.cardano(shelley: false).decimalValue
            
            return CardanoAddressResponse(balance: balance, recentTransactionsHashes: [], unspentOutputs: unspentOutputs)
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        let txHex: String = CBOR.array(
            [CBOR.utf8String(transaction.toHexString())]
        ).encode().toHexString()
        
        let submitBody = RosettaSubmitBody(networkIdentifier: .mainNet, signedTransaction: txHex)
        return provider.requestPublisher(.submitTransaction(baseUrl: baseUrl, submitBody: submitBody))
            .map(RosettaSubmitResponse.self, using: decoder)
            .eraseError()
            .map { $0.transactionIdentifier.hash ?? "" }
            .eraseToAnyPublisher()
    }
    
    private func balancePublisher(for address: String) -> AnyPublisher<RosettaBalanceResponse, Error> {
        provider
            .requestPublisher(.address(baseUrl: self.baseUrl,
                                       addressBody: RosettaAddressBody(networkIdentifier: .mainNet,
                                                                       accountIdentifier: RosettaAccountIdentifier(address: address))))
            .map(RosettaBalanceResponse.self, using: decoder)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func coinsPublisher(for address: String) -> AnyPublisher<RosettaCoinsResponse, Error> {
        provider
            .requestPublisher(.coins(baseUrl: self.baseUrl,
                                     addressBody: RosettaAddressBody(networkIdentifier: .mainNet,
                                                                     accountIdentifier: RosettaAccountIdentifier(address: address))))
            .map(RosettaCoinsResponse.self, using: decoder)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func mapToCardanoUnspentOutput(response: RosettaCoinsResponse, address: String) -> [CardanoUnspentOutput] {
        let coins = response.coins ?? []
        let outputs: [CardanoUnspentOutput] = coins.compactMap { coin -> CardanoUnspentOutput? in
            guard coin.amount?.currency?.symbol == cardanoCurrencySymbol,
                  coin.metadata == nil, // filter tokens while we don't support them
                  let splittedIdentifier = coin.coinIdentifier?.identifier?.split(separator: ":"),
                  splittedIdentifier.count == 2,
                  let index = Int(splittedIdentifier[1]) else {
                return nil
            }
            
            return CardanoUnspentOutput(address: address,
                                        amount: Decimal(coin.amount?.value) ?? 0,
                                        outputIndex: index,
                                        transactionHash: String(splittedIdentifier[0]))
        }
        
        return outputs
    }
}
