//
//  RadiantWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletCore

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
        let accountInfoPublisher = networkService
            .getInfo(address: wallet.address)
        
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

private extension RadiantWalletManager {
    func updateWallet(with addressInfo: RadiantAddressInfo) {
        let coinBalanceValue = addressInfo.balance / wallet.blockchain.decimalValue
        wallet.add(coinValue: coinBalanceValue)
        transactionBuilder.update(unspents: addressInfo.outputs)
    }
    
    func sendViaCompileTransaction(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        let hashesForSign: [Data]
        
        do {
            hashesForSign = try transactionBuilder.buildForSign(transaction: transaction)
        } catch {
            return .anyFail(error: error)
        }
    
        return signer
            .sign(hashes: hashesForSign, walletPublicKey: self.wallet.publicKey)
            .withWeakCaptureOf(self)
            .tryMap { walletManager, signatures in
                try walletManager.transactionBuilder.buildForSend(transaction: transaction, signatures: signatures)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, transactionData -> TransactionSendResult in
                print(transactionData.hexString)
                
                // TODO: - Need to send network service
                throw WalletError.failedToSendTx
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - WalletManager

extension RadiantWalletManager: WalletManager {
    var currentHost: String {
        networkService.host
    }
    
    var allowsFeeSelection: Bool {
        true
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        sendViaCompileTransaction(transaction, signer: signer)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return .justWithError(output: [
            .init(Amount(with: wallet.blockchain, value: 0.000000001))
        ])
        
//        networkService.estimatedFee()
//            .tryMap { [weak self] response throws -> [Fee] in
//                guard let self = self else { throw WalletError.empty }
//                
//                return [
//                    .init(Amount(with: wallet.blockchain, value: 0.000000001))
//                ]
//            }
//            .eraseToAnyPublisher()
    }
}

extension RadiantWalletManager {
    enum Constants {
        static let testTransactionSize = 256
        static let defaultFeeInCoinsPer1000Bytes = 1000
        static let normalFeeRate = 0.03
        static let requiredNumberOfConfirmationBlocks = 332
    }
}
