//
//  AlgorandWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AlgorandWalletManager: BaseManager {
    
    // MARK: - Private Properties
    
    private let networkService: AlgorandNetworkService
    
    // MARK: - Init
    
    init(wallet: Wallet, networkService: AlgorandNetworkService) throws {
        self.networkService = networkService
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getAccount(address: wallet.address)
            .sink(
                receiveCompletion: { completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        completion(.failure(error))
                    }
                },
                receiveValue: { [unowned self] response in
                    self.update(with: response, completion: completion)
                }
            )
    }
    
}

// MARK: - Private Implementation

private extension AlgorandWalletManager {
    func update(with response: AlgorandResponse.Account, completion: @escaping (Result<Void, Error>) -> Void) {
        let decimalBalance = Decimal(response.amount)
        let coinBalance = decimalBalance / wallet.blockchain.decimalValue
        
        wallet.add(coinValue: coinBalance)
        
        completion(.success(()))
    }
}

// MARK: - WalletManager protocol conformance

extension AlgorandWalletManager: WalletManager {
    var currentHost: String { "" }

    var allowsFeeSelection: Bool { false }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return .anyFail(error: WalletError.empty)
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        return .anyFail(error: WalletError.failedToSendTx)
    }
}
