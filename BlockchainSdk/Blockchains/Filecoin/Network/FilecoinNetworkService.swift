//
//  FilecoinNetworkService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

class FilecoinNetworkService: MultiNetworkProvider {
    let providers: [FilecoinNetworkProvider]
    var currentProviderIndex = 0
    
    init(providers: [FilecoinNetworkProvider]) {
        self.providers = providers
    }
    
    func getAccountInfo(address: String) -> AnyPublisher<FilecoinAccountInfo, Error> {
        providerPublisher { provider in
            provider
                .getActorInfo(address: address)
                .tryMap { response in
                    guard let balance = Decimal(stringValue: response.balance) else {
                        throw WalletError.failedToParseNetworkResponse()
                    }
                    
                    return FilecoinAccountInfo(
                        balance: balance,
                        nonce: response.nonce
                    )
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getMessageGas(transactionInfo: FilecoinTxInfo) -> AnyPublisher<FilecoinTxGasInfo, Error> {
        providerPublisher { provider in
            provider.getMessageGas(transactionInfo: transactionInfo)
        }
    }
    
    func submitTransaction(signedTransactionBody: FilecoinSignedTransactionBody) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider
                .submitTransaction(signedTransactionBody: signedTransactionBody)
                .map(\.hash)
                .eraseToAnyPublisher()
        }
    }
}
