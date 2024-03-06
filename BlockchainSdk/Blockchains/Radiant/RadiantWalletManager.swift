//
//  RadiantWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class RadiantWalletManager: BaseManager {
    
    // MARK: - Private Properties
    
    private let transactionBuilder: RadiantTransactionBuilder
    private let networkService: RadiantNetworkService
    
    // MARK: - Init
    
    init(wallet: Wallet, transactionBuilder: RadiantTransactionBuilder, networkService: RadiantNetworkService) throws {
        self.transactionBuilder = transactionBuilder
        self.networkService = networkService
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let addresses = wallet.addresses.map { $0.value }
        
        let accountInfoPublisher = networkService
            .getInfo(addresses: addresses)
        
        cancellable = accountInfoPublisher
            .withWeakCaptureOf(self)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            }, receiveValue: { (manager, response) in
                manager.updateWallet(with: response)
            })
    }
    
}

// MARK: - Private Implementation

extension RadiantWalletManager {
    func updateWallet(with response: [BitcoinResponse]) {
        let balance = response.reduce(into: 0) { $0 += $1.balance }
        let hasUnconfirmed = response.contains(where: { $0.hasUnconfirmed })
        let unspents = response.flatMap { $0.unspentOutputs }
        
        wallet.add(coinValue: balance)
        transactionBuilder.update(unspents: unspents)
        
        wallet.clearPendingTransaction()
        if hasUnconfirmed {
            response
                .flatMap { $0.pendingTxRefs }
                .forEach {
                    let mapper = PendingTransactionRecordMapper()
                    let transaction = mapper.mapToPendingTransactionRecord($0, blockchain: wallet.blockchain)
                    wallet.addPendingTransaction(transaction)
                }
        }
    }
}

// MARK: - WalletManager

extension RadiantWalletManager: WalletManager {
    var currentHost: String {
        networkService.host
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        guard let buildForSignHash = try? transactionBuilder.buildForSign(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        print(buildForSignHash)
        
        return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService.getFee()
            .tryMap { [weak self] response throws -> [Fee] in
                guard let self = self else { throw WalletError.empty }
                return [.init(Amount(with: .bitcoinCash, value: 1.0))]
            }
            .eraseToAnyPublisher()
    }
}

extension RadiantWalletManager {}
