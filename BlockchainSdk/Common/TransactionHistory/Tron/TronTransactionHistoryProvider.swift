//
//  TronTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 28.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class TronTransactionHistoryProvider<Mapper> where
    Mapper: BlockBookTransactionHistoryMapper,
    Mapper: BlockBookTransactionHistoryTotalPageCountExtractor
{
    private let blockBookProvider: BlockBookUtxoProvider
    private let mapper: Mapper

    private var page: TransactionHistoryIndexPage?
    private var totalPageCount: Int = 0

    init(
        blockBookProvider: BlockBookUtxoProvider,
        mapper: Mapper
    ) {
        self.blockBookProvider = blockBookProvider
        self.mapper = mapper
    }
}

// MARK: - TransactionHistoryProvider protocol conformance

extension TronTransactionHistoryProvider: TransactionHistoryProvider {
    var canFetchHistory: Bool {
        page == nil || (page?.number ?? Constants.initialPageNumber) < totalPageCount
    }

    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        return Deferred { [weak self] in
            Future { promise in
                if let page = self?.page {
                    promise(.success(page.number + 1))
                } else {
                    promise(.success(Constants.initialPageNumber))
                }
            }
        }
        .map { requestPage in
            return BlockBookTarget.AddressRequestParameters(
                page: requestPage,
                pageSize: request.limit,
                details: [.txslight],
                filterType: .init(amountType: request.amountType)
            )
        }
        .withWeakCaptureOf(self)
        .flatMap { historyProvider, parameters in
            return historyProvider
                .blockBookProvider
                .addressData(address: request.address, parameters: parameters)
        }
        .withWeakCaptureOf(self)
        .tryMap { historyProvider, response in
            let contractAddress = request.amountType.token?.contractAddress
            let totalPageCount = try historyProvider.mapper.extractTotalPageCount(
                from: response,
                contractAddress: contractAddress
            )

            return (response, totalPageCount)
        }
        .withWeakCaptureOf(self)
        .handleEvents(receiveOutput: { historyProvider, input in
            let (response, totalPageCount) = input
            historyProvider.page = TransactionHistoryIndexPage(number: response.page ?? Constants.initialPageNumber)
            historyProvider.totalPageCount = totalPageCount
        })
        .tryMap { historyProvider, input in
            let (response, _) = input
            let records = historyProvider.mapper.mapToTransactionRecords(response, amountType: request.amountType)

            return TransactionHistory.Response(records: records)
        }
        .eraseToAnyPublisher()
    }

    func reset() {
        page = nil
        totalPageCount = 0
    }
}

// MARK: - Constants

private extension TronTransactionHistoryProvider {
    enum Constants {
        // - Note: Tx history API has 1-based indexing (not 0-based indexing)
        static var initialPageNumber: Int { 1 }
    }
}
