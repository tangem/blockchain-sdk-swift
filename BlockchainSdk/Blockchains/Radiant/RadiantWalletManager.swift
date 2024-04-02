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
    
    /*
     TODO: - Will be implement in feature/IOS-6004-make-network-layer-radiant
     private let networkService: RadiantNetworkService
     */
    
    // MARK: - Init
    
    init(wallet: Wallet, transactionBuilder: RadiantTransactionBuilder) throws {
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        /*
         TODO: - Will be implement in feature/IOS-6004-make-network-layer-radiant
         */
    }
    
}

// MARK: - Private Implementation

private extension RadiantWalletManager {
    func updateWallet(with addressInfo: RadiantAddressInfo) {
        let coinBalanceValue = addressInfo.balance / wallet.blockchain.decimalValue
        wallet.add(coinValue: coinBalanceValue)
        transactionBuilder.update(utxo: addressInfo.outputs)
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
                guard 
                    let walletCorePublicKey = PublicKey(data: walletManager.wallet.publicKey.blockchainKey, type: .secp256k1),
                    signatures.count == hashesForSign.count
                else {
                    throw WalletError.failedToBuildTx
                }
                
                // Verify signature by public key
                guard signatures.enumerated().contains(where: { index, sig in
                    !walletCorePublicKey.verifyAsDER(signature: sig, message: Data(hashesForSign[index].reversed()))
                }) else {
                    throw WalletError.failedToBuildTx
                }
                
                return try walletManager.transactionBuilder.buildForSend(transaction: transaction, signatures: signatures)
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, transactionData -> AnyPublisher<String, Error> in
                /*
                 TODO: - Will be implement in feature/IOS-6004-make-network-layer-radiant
                 return walletManager.networkService.sendTransaction(data: transactionData)
                 */
                
                return .anyFail(error: WalletError.failedToSendTx)
            }
            .withWeakCaptureOf(self)
            .map { walletManager, txId -> TransactionSendResult in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: txId)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: txId)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - WalletManager

extension RadiantWalletManager: WalletManager {
    var currentHost: String {
        /*
         TODO: - Will be implement in feature/IOS-6004-make-network-layer-radiant
         networkService.host
         */
        
        return ""
    }
    
    var allowsFeeSelection: Bool {
        true
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        sendViaCompileTransaction(transaction, signer: signer)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        /*
         TODO: - Will be implement in feature/IOS-6004-make-network-layer-radiant
         */
        
        return .justWithError(output: [
            .init(Amount(with: wallet.blockchain, value: 0.1))
        ])
    }
}
