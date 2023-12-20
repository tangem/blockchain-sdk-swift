//
//  VeChainWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class VeChainWalletManager: BaseManager {
    private let networkService: VeChainNetworkService
    private let transactionBuilder: VeChainTransactionBuilder

    init(
        wallet: Wallet,
        energyToken: Token,
        networkService: VeChainNetworkService,
        transactionBuilder: VeChainTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
        cardTokens = [energyToken]
    }

    @available(*, unavailable)
    override init(wallet: Wallet) {
        fatalError("\(#function) has not been implemented")
    }

    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-5238)
    }
}

// MARK: - WalletManager protocol conformance

extension VeChainWalletManager: WalletManager {
    var currentHost: String { networkService.host }

    var allowsFeeSelection: Bool { false }

    func getFee(
        amount: Amount,
        destination: String
    ) -> AnyPublisher<[Fee], Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-5238)
        return .emptyFail
    }

    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-5238)
        return .emptyFail
    }
}
