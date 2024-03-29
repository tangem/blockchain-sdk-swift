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
        URL(string: rosettaUrl.url)!.hostOrUnknown
    }
    
    private let provider: NetworkProvider<RosettaTarget>
    private let rosettaUrl: RosettaUrl
    private let cardanoResponseMapper: CardanoResponseMapper

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    init(
        rosettaUrl: RosettaUrl,
        configuration: NetworkProviderConfiguration,
        cardanoResponseMapper: CardanoResponseMapper
    ) {
        self.rosettaUrl = rosettaUrl
        provider = NetworkProvider<RosettaTarget>(configuration: configuration)
        self.cardanoResponseMapper = cardanoResponseMapper
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

            return self.cardanoResponseMapper.mapToCardanoAddressResponse(
                tokens: tokens,
                unspentOutputs: unspentOutputs,
                recentTransactionsHashes: []
            )
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        let txHex: String = CBOR.array(
            [CBOR.utf8String(transaction.hexString.lowercased())]
        ).encode().toHexString()
        
        let submitBody = RosettaSubmitBody(networkIdentifier: .mainNet, signedTransaction: txHex)
        return provider
            .requestPublisher(.submitTransaction(baseUrl: rosettaUrl, submitBody: submitBody))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RosettaSubmitResponse.self, using: decoder)
            .eraseError()
            .map { $0.transactionIdentifier.hash ?? "" }
            .eraseToAnyPublisher()
    }
    
    private func balancePublisher(for address: String) -> AnyPublisher<RosettaBalanceResponse, Error> {
        provider
            .requestPublisher(.address(baseUrl: rosettaUrl,
                                       addressBody: RosettaAddressBody(networkIdentifier: .mainNet,
                                                                       accountIdentifier: RosettaAccountIdentifier(address: address))))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RosettaBalanceResponse.self, using: decoder)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func coinsPublisher(for address: String) -> AnyPublisher<RosettaCoinsResponse, Error> {
        provider
            .requestPublisher(.coins(baseUrl: rosettaUrl,
                                     addressBody: RosettaAddressBody(networkIdentifier: .mainNet,
                                                                     accountIdentifier: RosettaAccountIdentifier(address: address))))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(RosettaCoinsResponse.self, using: decoder)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func mapToCardanoUnspentOutput(response: RosettaCoinsResponse, address: String) -> [CardanoUnspentOutput] {
        guard let coins = response.coins else {
            return []
        }

        let outputs: [CardanoUnspentOutput] = coins.compactMap { coin -> CardanoUnspentOutput? in
            // We should ignore the output with metadata
            // Because we don't support a cardano tokens yet
            guard coin.metadata == nil else {
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
