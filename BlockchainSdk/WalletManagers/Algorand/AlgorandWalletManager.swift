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
    
    private let transactionBuilder: AlgorandTransactionBuilder
    
    // MARK: - Init
    
    init(transactionBuilder: AlgorandTransactionBuilder, wallet: Wallet) {
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }
}

// MARK: - WalletManager protocol conformance

extension AlgorandWalletManager: WalletManager {
    // TODO: - Insert host value
    var currentHost: String { "" }
    var allowsFeeSelection: Bool { false }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return .anyFail(error: WalletError.failedToGetFee)
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        return .anyFail(error: WalletError.failedToSendTx)
    }
}

/*
 Every account on Algorand must have a minimum balance of 100,000 microAlgos. If ever a transaction is sent that would result in a balance lower than the minimum, the transaction will fail. The minimum balance increases with each asset holding the account has (whether the asset was created or owned by the account) and with each application the account created or opted in. Destroying a created asset, opting out/closing out an owned asset, destroying a created app, or opting out an opted in app decreases accordingly the minimum balance.
 */
extension AlgorandWalletManager: MinimumBalanceRestrictable {
    var minimumBalance: Amount {
        wallet.amounts[.reserve] ?? Amount(with: wallet.blockchain, value: 0)
    }
}
