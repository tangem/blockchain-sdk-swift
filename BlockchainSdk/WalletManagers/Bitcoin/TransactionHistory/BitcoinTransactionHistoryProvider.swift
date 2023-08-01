//
//  BitcoinTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BitcoinTransactionHistoryProvider: MultiNetworkProvider {
    var currentProviderIndex: Int = 0
    var providers: [BlockBookUtxoProvider] {
        blockBookProviders
    }
    
    private let address: String
    private let blockBookProviders: [BlockBookUtxoProvider]
    private let mapper: BitcoinTransactionHistoryMapper

    init(
        address: String,
        blockBookProviders: [BlockBookUtxoProvider],
        mapper: BitcoinTransactionHistoryMapper
    ) {
        self.address = address
        self.blockBookProviders = blockBookProviders
        self.mapper = mapper
    }
}

extension BitcoinTransactionHistoryProvider: TransactionHistoryProvider {
    func loadTransactionHistory(page: Page) -> AnyPublisher<[TransactionRecord], Error> {
        providerPublisher { [weak self] provider in
            guard let self else {
                return .anyFail(error: WalletError.empty)
            }
            
            return provider.addressData(
                address: self.address,
                parameters: .init(page: page.number, pageSize: page.number, details: [.txslight])
            )
            .tryMap { [weak self] response -> [TransactionRecord] in
                guard let self else {
                    throw WalletError.empty
                }

                return self.mapper.mapToTransactionRecords(response)
            }
            .eraseToAnyPublisher()
        }
    }
}
