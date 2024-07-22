//
//  ICPWalletManager.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import Combine
import IcpKit

final class ICPWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkService.host }
    
    var allowsFeeSelection: Bool = false
    
    // MARK: - Private Properties
    
    private let txBuilder: ICPTransactionBuilder
    private let networkService: ICPNetworkService
    
    // MARK: - Init
    
    init(wallet: Wallet, networkService: ICPNetworkService) {
        self.txBuilder = .init(wallet: wallet)
        self.networkService = networkService
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkService.getBalance(address: wallet.address)
            .sink(
                receiveCompletion: { [weak self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        self?.wallet.clearAmounts()
                        self?.wallet.clearPendingTransaction()
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] balance in
                    self?.updateWallet(with: balance)
                    completion(.success(()))
                }
            )
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        .justWithError(output: [Fee(Amount(with: wallet.blockchain, value: Constants.fee))])
    }
    
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        fatalError()
    }
    
    // MARK: - Private implementation
    
    private func updateWallet(with balance: Decimal) {
        // Reset pending transaction
        if balance != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }
        
        wallet.add(coinValue: balance)
    }
}

private extension ICPWalletManager {
    enum Constants {
        static let fee = Decimal(stringValue: "0.0001")!
        static let readStateRetryCount = 3
        static let readStateRetryDelayMilliseconds = 500
    }
}
