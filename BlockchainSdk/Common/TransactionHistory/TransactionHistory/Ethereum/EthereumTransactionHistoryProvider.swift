//
//  EthereumTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class EthereumTransactionHistoryProvider {
    private let blockBookProvider: BlockBookUtxoProvider
    private let mapper: BlockBookTransactionHistoryMapper

    init(
        blockBookProvider: BlockBookUtxoProvider,
        mapper: BlockBookTransactionHistoryMapper
    ) {
        self.blockBookProvider = blockBookProvider
        self.mapper = mapper
    }
}

// MARK: - TransactionHistoryProvider

extension EthereumTransactionHistoryProvider: TransactionHistoryProvider {
    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        let parameters = BlockBookTarget.AddressRequestParameters(
            page: request.page.number,
            pageSize: request.page.limit,
            details: [.txslight],
            filterType: filterType(for: request.amountType)
        )
        
        return blockBookProvider.addressData(address: request.address, parameters: parameters)
            .tryMap { [weak self] response -> TransactionHistory.Response in
                guard let self else {
                    throw WalletError.empty
                }
                
                let records = self.mapper.mapToTransactionRecords(response, amountType: request.amountType)
                return TransactionHistory.Response(
                    totalPages: response.totalPages ?? 0,
                    totalRecordsCount: response.txs,
                    page: TransactionHistoryPage(
                        limit: response.itemsOnPage ?? 0,
                        type: .index,
                        number: response.page ?? 0,
                        total: response.txs
                    ),
                    records: records
                )
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension EthereumTransactionHistoryProvider {
    func filterType(for amountType: Amount.AmountType) -> BlockBookTarget.AddressRequestParameters.FilterType {
        switch amountType {
        case .coin, .reserve:
            return .coin
        case .token(let token):
            return .contract(token.contractAddress)
        }
    }
}
