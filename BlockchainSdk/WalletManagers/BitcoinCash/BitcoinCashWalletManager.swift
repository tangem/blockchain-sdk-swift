//
//  BitcoinCashWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

class BitcoinCashWalletManager: WalletManager {
    var txBuilder: BitcoinCashTransactionBuilder!
    var networkService: BitcoinCashNetworkService!
    
    var minimalFeePerByte: Decimal { 1 }
    var minimalFee: Decimal { 0.00001 }
    
    override var currentHost: String {
        networkService.currentHost
    }
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: self.wallet.address)
            .sink(receiveCompletion: {[unowned self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    private func updateWallet(with response: BitcoinResponse) {
        wallet.add(coinValue: response.balance)
        txBuilder.unspentOutputs = response.unspentOutputs
        if response.hasUnconfirmed {
            if wallet.transactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.transactions = []
        }
    }
}

extension BitcoinCashWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard let hashes = txBuilder.buildForSign(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: hashes,
                           cardId: wallet.cardId,
                           walletPublicKey: self.wallet.publicKey.signingPublicKey,
                           hdPath: self.wallet.publicKey.hdPath)
            .tryMap {[weak self] signatures -> String in
                guard let self = self else { throw WalletError.empty }
                
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signatures: signatures) else {
                    throw WalletError.failedToBuildTx
                }
                return tx.toHexString()
            }
            .flatMap {[weak self] tx -> AnyPublisher<Void, Error> in
                self?.networkService.send(transaction: tx).tryMap {[weak self] response in
                    guard let self = self else { throw WalletError.empty }
                    
                    self.wallet.add(transaction: transaction)
                }.eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .tryMap {[weak self] response throws -> [Amount] in
                guard let self = self else { throw WalletError.empty }
                
                let feePerByte = max(response.minimalSatoshiPerByte, self.minimalFeePerByte)
                
                guard let estimatedTxSize = self.getEstimateSize(for: Transaction(amount: amount, fee: Amount(with: amount, value: 0.0001),
                                                                                  sourceAddress: self.wallet.address,
                                                                                  destinationAddress: destination,
                                                                                  changeAddress: self.wallet.address)) else {
                    throw WalletError.failedToCalculateTxSize
                }
                
                let fee = (feePerByte * estimatedTxSize) / Blockchain.bitcoinCash(testnet: false).decimalValue
                let relayFee = self.minimalFee
                let finalFee = fee >= relayFee ? fee : relayFee
                
                return [
                    Amount(with: self.wallet.blockchain, value: finalFee)
                ]
            }
            .eraseToAnyPublisher()
    }
    
    private func getEstimateSize(for transaction: Transaction) -> Decimal? {
        guard let unspentOutputsCount = txBuilder.unspentOutputs?.count else {
            return nil
        }
        let signature = Data(repeating: UInt8(0x01), count: 64)
        let signatures: [Data] = .init(repeating: signature, count: unspentOutputsCount)
        guard let tx = txBuilder.buildForSend(transaction: transaction, signatures: signatures) else {
            return nil
        }
        
        return Decimal(tx.count + 1)
    }
}

extension BitcoinCashWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        networkService.getSignatureCount(address: wallet.address)
            .tryMap {
                if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
            }
            .eraseToAnyPublisher()
    }
}


extension BitcoinCashWalletManager: ThenProcessable { }
