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
    private let networkProvider: ElectrumNetworkProvider
    
    init(
        wallet: Wallet,
        transactionBuilder: NexaTransactionBuilder,
        networkProvider: ElectrumNetworkProvider
    ) {
        self.transactionBuilder = transactionBuilder
        self.networkProvider = networkProvider
        
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkProvider
            .getAddressInfo(address: wallet.address)
            .receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] info in
                self?.updateWallet(info: info)
                completion(.success(()))
            })
    }
}

// MARK: - Private

private extension NexaWalletManager {
    func updateWallet(info: ElectrumAddressInfo) {
        let balance = info.outputs.reduce(0) { result, output in
            if output.isConfirmed {
                return result + output.value
            }
            
            return result
        }

        wallet.add(coinValue: balance)
        wallet.clearPendingTransaction()
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
