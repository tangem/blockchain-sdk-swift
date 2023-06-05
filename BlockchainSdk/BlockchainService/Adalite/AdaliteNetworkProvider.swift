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
    
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error> {
        getUnspents(addresses: addresses)
            .flatMap {[weak self] unspents -> AnyPublisher<CardanoAddressResponse, Error> in
                guard let self = self else { return .emptyFail }

                return self.getBalance(addresses: addresses)
                    .map { balanceResponse -> CardanoAddressResponse in
                        // We should calculate the balance from outputs
                        // Because they don't contain tokens
                        var balance = unspents.reduce(0, { $0 + $1.amount })
                        balance /= Blockchain.cardano(shelley: false).decimalValue
                        let txHashes = balanceResponse.reduce([], { $0 + $1.transactions })
                        return CardanoAddressResponse(balance: balance, recentTransactionsHashes: txHashes, unspentOutputs: unspents)
                    }
                    .eraseToAnyPublisher()
            }
            .retry(2)
            .eraseToAnyPublisher()
    }
    
    private func getUnspents(addresses: [String]) -> AnyPublisher<[CardanoUnspentOutput], Error> {
        provider
            .requestPublisher(.unspents(addresses: addresses, url: adaliteUrl))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(AdaliteBaseResponseDTO<String, [AdaliteUnspentOutputResponseDTO]>.self)
            .tryMap { response throws -> [CardanoUnspentOutput] in
                guard let unspentOutputs = response.right else {
                    throw response.left ?? WalletError.empty
                }

                return unspentOutputs.compactMap { output -> CardanoUnspentOutput? in
                    // We need to ignore unspents with tokens (until we start supporting tokens)
                    guard output.cuCoins.getTokens.isEmpty else {
                        return nil
                    }
                    
                    guard let amount = Decimal(string: output.cuCoins.getCoin) else {
                        return nil
                    }
                    
                    return CardanoUnspentOutput(address: output.cuAddress,
                                                amount: amount,
                                                outputIndex: output.cuOutIndex,
                                                transactionHash: output.cuId)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func getBalance(addresses: [String]) -> AnyPublisher<[AdaliteBalanceResponse], Error> {
        .multiAddressPublisher(addresses: addresses, requestFactory: { [weak self] in
            guard let self = self else { return .emptyFail }
            
            return self.provider
                .requestPublisher(.address(address: $0, url: self.adaliteUrl))
                .filterSuccessfulStatusAndRedirectCodes()
                .map(AdaliteBaseResponseDTO<String, AdaliteBalanceResponseDTO>.self)
                .tryMap { response throws -> AdaliteBalanceResponse in
                    guard let addressData = response.right else {
                        throw response.left ?? WalletError.empty
                    }

                    let balance = Decimal(string: addressData.caBalance.getCoin) ?? 0
                    let convertedValue = balance / Blockchain.cardano(shelley: false).decimalValue
                    let transactions = addressData.caTxList.map { $0.ctbId }

                    return AdaliteBalanceResponse(balance: convertedValue, transactions: transactions)
                }
                .eraseToAnyPublisher()
        })
    }
}
