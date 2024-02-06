//
//  AptosWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class AptosWalletManager: BaseManager {
    
    // MARK: - Private Properties

    private let transactionBuilder: AptosTransactionBuilder
    
    // MARK: - Init
    
    init(wallet: Wallet, transactionBuilder: AptosTransactionBuilder) {
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
    
}

extension AptosWalletManager: WalletManager {
    
    var currentHost: String {
        // TODO: - Make host after created network layer
        ""
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        // TODO: - Make implementation after created transaction builder
        return .anyFail(error: WalletError.failedToSendTx)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return .anyFail(error: WalletError.failedToGetFee)
    }
    
}
