//
//  AdaliteNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class AdaliteNetworkProvider: CardanoNetworkProvider {
    private let adaliteUrl: AdaliteUrl
    private let provider: NetworkProvider<AdaliteTarget>
    private let cardanoResponseMapper: CardanoResponseMapper
    
    var host: String {
        AdaliteTarget.address(address: "", url: adaliteUrl).baseURL.hostOrUnknown
    }

    init(
        adaliteUrl: AdaliteUrl,
        configuration: NetworkProviderConfiguration,
        cardanoResponseMapper: CardanoResponseMapper
    ) {
        self.adaliteUrl = adaliteUrl
        provider = NetworkProvider<AdaliteTarget>(configuration: configuration)
        self.cardanoResponseMapper = cardanoResponseMapper
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        provider
            .requestPublisher(.send(base64EncodedTx: transaction.base64EncodedString(), url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
    }
    
    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error> {
        Publishers
            .Zip(getUnspents(addresses: addresses), getBalance(addresses: addresses))
            .tryMap { [weak self] unspents, responses -> CardanoAddressResponse in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                let txHashes = responses.flatMap { $0.transactions }
                return self.cardanoResponseMapper.mapToCardanoAddressResponse(
                    tokens: tokens,
                    unspentOutputs: unspents,
                    recentTransactionsHashes: txHashes
                )
            }
            .retry(2)
            .eraseToAnyPublisher()
    }
    
    private func getUnspents(addresses: [String]) -> AnyPublisher<[CardanoUnspentOutput], Error> {
        provider
            .requestPublisher(.unspents(addresses: addresses, url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(AdaliteBaseResponseDTO<String, [AdaliteUnspentOutputResponseDTO]>.self)
            .tryMap { [weak self] response throws -> [CardanoUnspentOutput] in
                guard let self, let unspentOutputs = response.right else {
                    throw response.left ?? WalletError.empty
                }

                return unspentOutputs.compactMap { self.mapToCardanoUnspentOutput($0) }
            }
            .eraseToAnyPublisher()
    }
    
    private func getBalance(addresses: [String]) -> AnyPublisher<[AdaliteBalanceResponse], Error> {
        .multiAddressPublisher(addresses: addresses) { [weak self] in
            guard let self = self else { return .emptyFail }
            
            return self.provider
                .requestPublisher(.address(address: $0, url: self.adaliteUrl))
                .filterSuccessfulStatusAndRedirectCodes()
                .map(AdaliteBaseResponseDTO<String, AdaliteBalanceResponseDTO>.self)
                .tryMap { [weak self] response throws -> AdaliteBalanceResponse in
                    guard let self, let balanceResponse = response.right else {
                        throw response.left ?? WalletError.empty
                    }

                    return self.mapToAdaliteBalanceResponse(balanceResponse)
                }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Mapping

private extension AdaliteNetworkProvider {
    func mapToAdaliteBalanceResponse(_ balanceResponse: AdaliteBalanceResponseDTO) -> AdaliteBalanceResponse {
        let transactions = balanceResponse.caTxList.map { $0.ctbId }
        return AdaliteBalanceResponse(transactions: transactions)
    }
    
    func mapToCardanoUnspentOutput(_ output: AdaliteUnspentOutputResponseDTO) -> CardanoUnspentOutput? {
        guard let amount = Decimal(string: output.cuCoins.getCoin) else {
            return nil
        }
        
        // We should ignore the output with metadata
        // Because we don't support a cardano tokens yet
        guard output.cuCoins.getTokens.isEmpty else {
            return nil
        }
        
        let assets: [CardanoUnspentOutput.Asset] = output.cuCoins.getTokens.compactMap { token in
            guard let amount = Int(token.quantity) else {
                return nil
            }
            
            return CardanoUnspentOutput.Asset(policyID: token.policyId, assetNameHex: token.assetName, amount: amount)
        }
        
        return CardanoUnspentOutput(address: output.cuAddress,
                                    amount: amount,
                                    outputIndex: output.cuOutIndex,
                                    transactionHash: output.cuId,
                                    assets: assets)
    }
}
