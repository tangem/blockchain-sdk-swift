//
//  EthereumTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class EthereumTransactionHistoryProvider: MultiNetworkProvider {
    var currentProviderIndex: Int = 0
    var providers: [BlockBookUtxoProvider] {
        blockBookProviders
    }
    
    private let blockBookProviders: [BlockBookUtxoProvider]
    private let mapper: TransactionHistoryMapper

    init(
        blockBookProviders: [BlockBookUtxoProvider],
        mapper: TransactionHistoryMapper
    ) {
        self.blockBookProviders = blockBookProviders
        self.mapper = mapper
    }
}

extension EthereumTransactionHistoryProvider: TransactionHistoryProvider {
    func loadTransactionHistory(address: String, page: Page) -> AnyPublisher<TransactionHistoryResponse, Error> {
        providerPublisher { [weak self] provider in
            guard let self else {
                return .anyFail(error: WalletError.empty)
            }
            
            return provider.addressData(
                address: address,
                parameters: .init(page: page.number, pageSize: page.size, details: [.txs])
            )
            .tryMap { [weak self] response -> TransactionHistoryResponse in
                guard let self else {
                    throw WalletError.empty
                }
                
                let records = self.mapper.mapToTransactionRecords(response)
                return TransactionHistoryResponse(
                    totalPages: response.totalPages,
                    totalRecordsCount: response.txs,
                    page: Page(number: response.page, size: response.itemsOnPage),
                    records: records
                )
            }
            .eraseToAnyPublisher()
        }
    }
}
