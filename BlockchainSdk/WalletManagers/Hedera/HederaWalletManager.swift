//
//  HederaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class HederaWalletManager: BaseManager {
    private let networkService: HederaNetworkService
    private let transactionBuilder: HederaTransactionBuilder

    init(
        wallet: Wallet,
        networkService: HederaNetworkService,
        transactionBuilder: HederaTransactionBuilder
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
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4561)
        completion(.success(()))
    }
}

// MARK: - WalletManager protocol conformance

extension HederaWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }  // TODO: Andrey Fedorov - Allow custom fees for Hedera (IOS-4561)?

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4561)
        return .anyFail(error: WalletError.failedToGetFee)
    }

    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4561)
        return .anyFail(error: WalletError.failedToSendTx)
    }
}
