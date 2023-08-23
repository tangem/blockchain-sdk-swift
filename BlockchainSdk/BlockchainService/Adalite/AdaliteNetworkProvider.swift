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
    
    var host: String {
        AdaliteTarget.address(address: "", url: adaliteUrl).baseURL.hostOrUnknown
    }
    
    var decimalValue: Decimal {
        Blockchain.cardano(extended: false).decimalValue
    }
    
    init(baseUrl: AdaliteUrl, configuration: NetworkProviderConfiguration) {
        adaliteUrl = baseUrl
        provider = NetworkProvider<AdaliteTarget>(configuration: configuration)
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

                return self.mapToCardanoAddressResponse(responses: responses, unspentOutputs: unspents, tokens: tokens)
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
    
    func mapToCardanoAddressResponse(
        responses: [AdaliteBalanceResponse],
        unspentOutputs: [CardanoUnspentOutput],
        tokens: [Token]
    ) -> CardanoAddressResponse {
        let txHashes = responses.flatMap { $0.transactions }
        let coinBalance: Decimal = unspentOutputs.reduce(0) { result, output in
            result + output.amount / decimalValue
        }

        let tokenBalances: [Token: Decimal] = tokens.reduce(into: [:]) { tokenBalances, token in
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
        
        return CardanoAddressResponse(
            balance: coinBalance,
            tokenBalances: tokenBalances,
            recentTransactionsHashes: txHashes,
            unspentOutputs: unspentOutputs
        )
    }
}
