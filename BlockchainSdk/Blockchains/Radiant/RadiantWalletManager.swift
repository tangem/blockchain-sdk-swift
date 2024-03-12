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
        let preparedAddress: String
        
        do {
            preparedAddress = try RadiantUtils().prepareWallet(address: wallet.address)
        } catch {
            completion(.failure(error))
            return
        }
        
        let accountInfoPublisher = networkService
            .getInfo(address: preparedAddress)
        
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
                print(response)
//                manager.updateWallet(with: response)
            })
    }
    
}

// MARK: - Private Implementation

private extension RadiantWalletManager {
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
    
    func sendViaCompileTransaction(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, Error> {
        let hashPublicKeysForSign: [WalletCore.TW_Bitcoin_Proto_HashPublicKey]
        
        do {
            hashPublicKeysForSign = try transactionBuilder.buildForSign(transaction: transaction)
        } catch {
            return .anyFail(error: error)
        }
    
        return signer
            .sign(hashes: hashPublicKeysForSign.map { $0.dataHash }, walletPublicKey: self.wallet.publicKey)
            .withWeakCaptureOf(self)
            .tryMap { walletManager, signatures in
                let signatureInfos = signatures.enumerated().map {
                    SignatureInfo(signature: $1, publicKey: hashPublicKeysForSign[$0].publicKeyHash)
                }
                
                return try walletManager.transactionBuilder.buildForSend(
                    transaction: transaction,
                    signatures: signatureInfos
                )
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
        return .anyFail(error: WalletError.failedToGetFee)
//        return networkService.getFee()
//            .tryMap { [weak self] response throws -> [Fee] in
//                guard let self = self else { throw WalletError.empty }
//                return [
//                    .init(Amount(with: wallet.blockchain, value: 0.000000001))
//                ]
//            }
//            .eraseToAnyPublisher()
    }
}

extension RadiantWalletManager {}
