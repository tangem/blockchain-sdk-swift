//
//  AlgorandWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AlgorandWalletManager: BaseManager {}

// MARK: - WalletManager protocol conformance

extension AlgorandWalletManager: WalletManager {
    var currentHost: String { "" }

    var allowsFeeSelection: Bool { true }

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
