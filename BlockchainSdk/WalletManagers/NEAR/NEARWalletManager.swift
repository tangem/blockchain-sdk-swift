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
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4071)
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
