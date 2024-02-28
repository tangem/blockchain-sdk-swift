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
    
    private var page: TransactionHistoryIndexPage?
    private var totalPages: Int = 0
    private var totalRecordsCount: Int = 0

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
    var canFetchHistory: Bool {
        page == nil || (page?.number ?? 0) < totalPages
    }
    
    var description: String {
        return "number: \(String(describing: page?.number)); \(totalPages); \(totalRecordsCount)"
    }
    
    func reset() {
        page = nil
        totalPages = 0
        totalRecordsCount = 0
    }
    
    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        let requestPage: Int
        
        // if indexing is created, load the next page
        if let page {
            requestPage = page.number + 1
        } else {
            requestPage = 0
        }
        
        let parameters = BlockBookTarget.AddressRequestParameters(
            page: requestPage,
            pageSize: request.limit,
            details: [.txslight],
            filterType: filterType(for: request.amountType)
        )
        
        return blockBookProvider.addressData(address: request.address, parameters: parameters)
            .tryMap { [weak self] response -> TransactionHistory.Response in
                guard let self else {
                    throw WalletError.empty
                }
                
                let records = self.mapper.mapToTransactionRecords(response, amountType: request.amountType)
                
                self.page = TransactionHistoryIndexPage(number: response.page ?? 0)
                self.totalPages = response.totalPages ?? 0
                self.totalRecordsCount = response.txs
                
                return TransactionHistory.Response(records: records)
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
