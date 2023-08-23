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

/// https://docs.cardano.org/cardano-components/cardano-rosetta/get-started-rosetta
class RosettaNetworkProvider: CardanoNetworkProvider {
    var host: String {
        URL(string: baseUrl.url)!.hostOrUnknown
    }
    
    private let provider: NetworkProvider<RosettaTarget>
    private let baseUrl: RosettaUrl
    private let cardanoCurrencySymbol: String = Blockchain.cardano(extended: false).currencySymbol
    private var decimalValue: Decimal {
        Blockchain.cardano(extended: false).decimalValue
    }
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    init(baseUrl: RosettaUrl, configuration: NetworkProviderConfiguration) {
        self.baseUrl = baseUrl
        provider = NetworkProvider<RosettaTarget>(configuration: configuration)
    }
    
    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error> {
        typealias Response = (coins: RosettaCoinsResponse, address: String)
        
        return AnyPublisher<Response, Error>.multiAddressPublisher(addresses: addresses) { [weak self] address -> AnyPublisher<Response, Error> in
            guard let self else {
                return .emptyFail
            }
            
            return coinsPublisher(for: address)
                .map { (coins: $0, address: address) }
                .eraseToAnyPublisher()
        }
        .tryMap { [weak self] responses -> CardanoAddressResponse in
            guard let self else {
                throw WalletError.empty
            }
            
            let unspentOutputs = responses.flatMap {
                self.mapToCardanoUnspentOutput(response: $0.coins, address: $0.address)
            }

            var coinBalance: Decimal = 0
            var tokenBalances: [Token: Decimal] = tokens.reduce(into: [:]) { tokenBalances, token in
                // Collecting of all output balance
                tokenBalances[token, default: 0] += unspentOutputs.reduce(0) { result, output in
                    // Sum with each asset in output amount
                    result + output.assets.reduce(into: 0) { result, asset in
                        // We can not compare full contractAddress and policyId
                        // Because from API we receive only the policyId e.g. `1d7f33bd23d85e1a25d87d86fac4f199c3197a2f7afeb662a0f34e1e`
                        // But from our API sometimes we receive the contractAddress like `policyId + assetNameHex`
                        // e.g. 1d7f33bd23d85e1a25d87d86fac4f199c3197a2f7afeb662a0f34e1e776f726c646d6f62696c65746f6b656e
                        if token.contractAddress.hasPrefix(asset.policyID) {
                            result += Decimal(asset.amount) / token.decimalValue
                        }
                    }
                }
            }

            unspentOutputs.forEach { output in
                coinBalance += output.amount / self.decimalValue
            }
            
            return CardanoAddressResponse(balance: coinBalance, tokenBalances: tokenBalances, recentTransactionsHashes: [], unspentOutputs: unspentOutputs)
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
        guard let coins = response.coins else {
            return []
        }

        let outputs: [CardanoUnspentOutput] = coins.compactMap { coin -> CardanoUnspentOutput? in
            // It should be always true, but someone added this check
            // I'll leave like exist
            guard coin.amount?.currency?.symbol == cardanoCurrencySymbol else {
                return nil
            }
            
            guard let (index, hash) = parseIdentifier(coin.coinIdentifier?.identifier),
                  let amountValue = coin.amount?.value,
                  let amount = Decimal(amountValue) else {
                return nil
            }

            let assets = mapToAssets(metadata: coin.metadata)
            return CardanoUnspentOutput(
                address: address,
                amount: amount,
                outputIndex: index,
                transactionHash: hash,
                assets: assets
            )
        }

        return outputs
    }
    
    /// We receive every identifier in format
    /// `482d88eb2d3b40b8a4e6bb8545cef842a5703e8f9eab9e3caca5c2edd1f31a7f:0`
    /// When the first part is transactionHash
    /// And the second path is outputIndex
    func parseIdentifier(_ identifier: String?) -> (index: Int, hash: String)? {
        guard let splittedIdentifier = identifier?.split(separator: ":"), splittedIdentifier.count == 2 else {
            return nil
        }
        
        guard let index = Int(splittedIdentifier[1])else {
            return nil
        }
        
        return (index: index, hash: String(splittedIdentifier[0]))
    }
        
    func mapToAssets(metadata: [String: [RosettaMetadataValue]]?) -> [CardanoUnspentOutput.Asset] {
        guard let metadata = metadata else {
            return []
        }
        
        let assets = metadata.values.reduce([]) { result, values -> [CardanoUnspentOutput.Asset] in
            let tokens = values.reduce([]) { result, value -> [CardanoUnspentOutput.Asset] in
                    guard let tokens = value.tokens else {
                        return result
                    }

                    return result + tokens.compactMap { tokenValue -> CardanoUnspentOutput.Asset? in
                        guard let value = tokenValue.value,
                              let amount = Int(value),
                              // symbol in ASCII HEX, e.g. 41474958 = AGIX
                              let assetNameHex = tokenValue.currency?.symbol,
                              let policyId = tokenValue.currency?.metadata?.policyId else {
                            return nil
                        }
                        
                        return CardanoUnspentOutput.Asset(policyID: policyId, assetNameHex: assetNameHex, amount: amount)
                    }
                }
            
            
            return result + tokens
        }
        
        return assets
    }
}
