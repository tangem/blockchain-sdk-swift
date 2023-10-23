//
//  NEARWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class NEARWalletManager: BaseManager {
    /// Current actual values, fetched once per app session.
    private static var cachedProtocolConfig: NEARProtocolConfig?

    /// Fallback values that are actual at the time of implementation (Q4 2023).
    private static var fallbackProtocolConfig: NEARProtocolConfig {
        NEARProtocolConfig(
           senderIsReceiver: .init(
               cumulativeExecutionCost: Decimal(115123062500) + Decimal(108059500000),
               cumulativeSendCost: Decimal(115123062500) + Decimal(108059500000)
           ),
           senderIsNotReceiver: .init(
               cumulativeExecutionCost: Decimal(115123062500) + Decimal(108059500000),
               cumulativeSendCost: Decimal(115123062500) + Decimal(108059500000)
           )
       )
    }

    private let networkService: NEARNetworkService
    private let transactionBuilder: NEARTransactionBuilder

    init(
        wallet: Wallet,
        networkService: NEARNetworkService,
        transactionBuilder: NEARTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(accountId: wallet.address)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        self.wallet.clearAmounts()
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                },
                receiveValue: { [weak self] value in
                    self?.wallet.add(amount: value.amount)
                }
            )
    }

    private func getProtocolConfig() -> AnyPublisher<NEARProtocolConfig, Never> {
        return Deferred { [networkService] in
            if let protocolConfig = Self.cachedProtocolConfig {
                return Just(protocolConfig)
                    .eraseToAnyPublisher()
            }

            return networkService
                .getProtocolConfig()
                .handleEvents(receiveOutput: { Self.cachedProtocolConfig = $0 })
                .replaceError(with: Self.fallbackProtocolConfig)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - WalletManager protocol conformance

extension NEARWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }

    func getFee(
        amount: Amount,
        destination: String
    ) -> AnyPublisher<[Fee], Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4071)
        return .emptyFail
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4071)
        return .emptyFail
    }
}
