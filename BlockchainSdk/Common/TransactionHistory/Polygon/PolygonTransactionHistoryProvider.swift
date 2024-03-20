//
//  PolygonTransactionHistoryProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class PolygonTransactionHistoryProvider<Mapper> where 
    Mapper: TransactionHistoryMapper,
    Mapper.Response == PolygonTransactionHistoryResult
{
    private let mapper: Mapper
    private let networkProvider: NetworkProvider<PolygonTransactionHistoryTarget>
    private let targetConfiguration: PolygonTransactionHistoryTarget.Configuration

    private var page: TransactionHistoryIndexPage?
    private var hasReachedEnd = false

    init(
        mapper: Mapper,
        networkConfiguration: NetworkProviderConfiguration,
        targetConfiguration: PolygonTransactionHistoryTarget.Configuration
    ) {
        self.mapper = mapper
        self.networkProvider = .init(configuration: networkConfiguration)
        self.targetConfiguration = targetConfiguration
    }

    private func makeTarget(
        for request: TransactionHistory.Request,
        requestedPageNumber: Int
    ) -> PolygonTransactionHistoryTarget {
        let target: PolygonTransactionHistoryTarget.Target
        if let contractAddress = request.amountType.token?.contractAddress {
            target = .getTokenTransactionHistory(
                address: request.address,
                contract: contractAddress,
                page: requestedPageNumber,
                limit: request.limit
            )
        } else {
            target = .getCoinTransactionHistory(
                address: request.address,
                page: requestedPageNumber,
                limit: request.limit
            )
        }

        return PolygonTransactionHistoryTarget(configuration: targetConfiguration, target: target)
    }
}

// MARK: - TransactionHistoryProvider protocol conformance

extension PolygonTransactionHistoryProvider: TransactionHistoryProvider {
    var canFetchHistory: Bool {
        page == nil || !hasReachedEnd
    }
    
    func loadTransactionHistory(request: TransactionHistory.Request) -> AnyPublisher<TransactionHistory.Response, Error> {
        return Deferred { [weak self] in
            Future { promise in
                if let currentPageNumber = self?.page?.number {
                    promise(.success(currentPageNumber + 1))
                } else {
                    promise(.success(Constants.initialPageNumber))
                }
            }
        }
        .withWeakCaptureOf(self)
        .flatMap { historyProvider, requestedPageNumber in
            return Just(request)
                .withWeakCaptureOf(historyProvider)
                .map { historyProvider, request in
                    return historyProvider.makeTarget(for: request, requestedPageNumber: requestedPageNumber)
                }
                .withWeakCaptureOf(historyProvider)
                .map { historyProvider, target in
                    return historyProvider
                        .networkProvider
                        .requestPublisher(target)
                        .filterSuccessfulStatusAndRedirectCodes()
                        .map(PolygonTransactionHistoryResult.self)
                        .eraseError()
                }
                .switchToLatest()
                .withWeakCaptureOf(historyProvider)
                .handleEvents(receiveOutput: { historyProvider, _ in
                    historyProvider.page = TransactionHistoryIndexPage(number: requestedPageNumber)
                })
                .tryMap { historyProvider, result in
                    return try historyProvider
                        .mapper
                        .mapToTransactionRecords(result, walletAddress: request.address, amountType: request.amountType)
                }
                .tryCatch { [weak historyProvider] error in
                    if let error = error as? PolygonScanAPIError, error == .endOfTransactionHistoryReached {
                        historyProvider?.hasReachedEnd = true
                        return Just(TransactionHistory.Response(records: []))
                    }
                    throw error
                }
        }
        .eraseToAnyPublisher()
    }
    
    func reset() {
        page = nil
        hasReachedEnd = false
    }
}

// MARK: - Constants

private extension PolygonTransactionHistoryProvider {
    enum Constants {
        // - Note: Tx history API has 1-based indexing (not 0-based indexing)
        static var initialPageNumber: Int { 1 }
    }
}

