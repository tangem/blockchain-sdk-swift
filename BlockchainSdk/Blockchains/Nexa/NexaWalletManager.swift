//
//  NexaWalletManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class NexaWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkProvider.host }

    private let transactionBuilder: NexaTransactionBuilder
    private let networkProvider: NexaNetworkProvider
    
    init(
        wallet: Wallet,
        transactionBuilder: NexaTransactionBuilder,
        networkProvider: NexaNetworkProvider
    ) {
        self.transactionBuilder = transactionBuilder
        self.networkProvider = networkProvider
        
        super.init(wallet: wallet)
    }
}

// MARK: - TransactionSender

extension NexaWalletManager {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        fatalError("TODO")
    }
}

// MARK: - TransactionFeeProvider

extension NexaWalletManager {
    var allowsFeeSelection: Bool { false }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        fatalError("TODO")
    }
}
