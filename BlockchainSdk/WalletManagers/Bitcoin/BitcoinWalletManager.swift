//
//  Bitcoin.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine
import BitcoinCore

class BitcoinWalletManager: BaseManager, WalletManager {
    var allowsFeeSelection: Bool { true }
    var txBuilder: BitcoinTransactionBuilder!
    var networkService: BitcoinNetworkProvider!
    
    var minimalFeePerByte: Decimal { 10 }
    var minimalFee: Decimal { 0.00001 }
    
    var loadedUnspents: [BitcoinUnspentOutput] = []
    
    var currentHost: String { networkService.host }
    var outputsCount: Int? { loadedUnspents.count }
    
    func update(completion: @escaping (Result<Void, Error>)-> Void)  {
        cancellable = networkService.getInfo(addresses: wallet.addresses.map{ $0.value })
            .eraseToAnyPublisher()
            .subscribe(on: DispatchQueue.global())
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
    
    func updateWallet(with response: [BitcoinResponse]) {
        let balance = response.reduce(into: 0) { $0 += $1.balance }
        let hasUnconfirmed = response.contains(where: { $0.hasUnconfirmed })
        let unspents = response.flatMap { $0.unspentOutputs }
        
        wallet.add(coinValue: balance)
        loadedUnspents = unspents
        txBuilder.unspentOutputs = unspents
        
        wallet.transactions.removeAll()
        if hasUnconfirmed {
            response.forEach {
                $0.pendingTxRefs.forEach { wallet.addPendingTransaction($0) }
            }
        }
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .tryMap {[weak self] response throws -> [Amount] in
                guard let self = self else { throw WalletError.empty }
                
                return self.processFee(response, amount: amount, destination: destination)
                
            }
            .eraseToAnyPublisher()
    }
    
    private func send(_ transaction: Transaction, signer: TransactionSigner, sequence: Int, isPushingTx: Bool) -> AnyPublisher<TransactionSendResult, Error> {
        guard let hashes = txBuilder.buildForSign(transaction: transaction, sequence: sequence) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: hashes,
                           walletPublicKey: self.wallet.publicKey)
            .tryMap {[weak self] signatures -> (String) in
                guard let self = self else { throw WalletError.empty }
                
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signatures: signatures, sequence: sequence) else {
                    throw WalletError.failedToBuildTx
                }
                
                return tx.toHexString()
            }
            .flatMap {[weak self] tx -> AnyPublisher<TransactionSendResult, Error> in
                guard let self = self else { return .emptyFail }
                
                let txHashPublisher: AnyPublisher<String, Error>
                if isPushingTx {
                    txHashPublisher = self.networkService.push(transaction: tx)
                } else {
                    txHashPublisher = self.networkService.send(transaction: tx)
                }
                
                return txHashPublisher.tryMap {[weak self] sendResponse in
                    guard let self = self else { throw WalletError.empty }
                    
                    var sendedTx = transaction
                    sendedTx.hash = sendResponse
                    self.wallet.add(transaction: sendedTx)
                    return TransactionSendResult(hash: sendResponse)
                }
                .mapError { SendTxError(error: $0, tx: tx) }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func processFee(_ response: BitcoinFee, amount: Amount, destination: String) -> [Amount] {
        // Don't remove `.rounded` from here, intValue can sometimes go crazy
        // e.g. with the Decimal of (662701 / 3), producing 0 integer
        var minRate = (max(response.minimalSatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .down) as NSDecimalNumber).intValue
        var normalRate = (max(response.normalSatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .down) as NSDecimalNumber).intValue
        var maxRate = (max(response.prioritySatoshiPerByte, minimalFeePerByte).rounded(roundingMode: .down) as NSDecimalNumber).intValue
        
        var minFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: minRate, senderPay: false, changeScript: nil, sequence: .max)
        var normalFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: normalRate, senderPay: false, changeScript: nil, sequence: .max)
        var maxFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: maxRate, senderPay: false, changeScript: nil, sequence: .max)
        
        let minimalFeeRate = (((minimalFee * Decimal(minRate)) / minFee).rounded(scale: 0, roundingMode: .up) as NSDecimalNumber).intValue
        let minimalFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: minimalFeeRate, senderPay: false, changeScript: nil, sequence: .max)
        if minFee < minimalFee {
            minRate = minimalFeeRate
            minFee = minimalFee
        }
        
        if normalFee < minimalFee {
            normalRate = minimalFeeRate
            normalFee = minimalFee
        }
        
        if maxFee < minimalFee {
            maxRate = minimalFeeRate
            maxFee = minimalFee
        }
        
        txBuilder.feeRates = [:]
        txBuilder.feeRates[minFee] = minRate
        txBuilder.feeRates[normalFee] = normalRate
        txBuilder.feeRates[maxFee] = maxRate
        return [
            Amount(with: wallet.blockchain, value: minFee),
            Amount(with: wallet.blockchain, value: normalFee),
            Amount(with: wallet.blockchain, value: maxFee)
        ]
    }
}

@available(iOS 13.0, *)
extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        txBuilder.unspentOutputs = loadedUnspents
        return send(transaction, signer: signer, sequence: SequenceValues.default.rawValue, isPushingTx: false)
    }
}

extension BitcoinWalletManager: TransactionPusher {
    func isPushAvailable(for transactionHash: String) -> Bool {
        guard networkService.supportsTransactionPush else {
            return false
        }
        
        guard let tx = wallet.transactions.first(where: { $0.hash == transactionHash }) else {
            return false
        }
        
        let userAddresses = wallet.addresses.map { $0.value }
        
        guard userAddresses.contains(tx.sourceAddress) else {
            return false
        }
        
        guard let params = tx.params as? BitcoinTransactionParams, tx.status == .unconfirmed else {
            return false
        }
        
        var containNotRbfInput: Bool = false
        var containOtherOutputAccount: Bool = false
        params.inputs.forEach {
            if !userAddresses.contains($0.address) {
                containOtherOutputAccount = true
            }
            if $0.sequence >= SequenceValues.disabledReplacedByFee.rawValue {
                containNotRbfInput = true
            }
        }
        
        return !containNotRbfInput && !containOtherOutputAccount
    }
    
    func getPushFee(for transactionHash: String) -> AnyPublisher<[Amount], Error> {
        guard let tx = wallet.transactions.first(where: { $0.hash == transactionHash }) else {
            return .anyFail(error: BlockchainSdkError.failedToFindTransaction)
        }
        
        txBuilder.unspentOutputs = loadedUnspents.filter { $0.transactionHash != transactionHash }
        
        return getFee(amount: tx.amount, destination: tx.destinationAddress)
            .map { [weak self] in
                self?.txBuilder.unspentOutputs = self?.loadedUnspents
                return $0
            }
            .eraseToAnyPublisher()
    }
    
    func pushTransaction(with transactionHash: String, newTransaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard let oldTx = wallet.transactions.first(where: { $0.hash == transactionHash }) else {
            return .anyFail(error: BlockchainSdkError.failedToFindTransaction)
        }
        
        guard oldTx.fee.value < newTransaction.fee.value else {
            return .anyFail(error: BlockchainSdkError.feeForPushTxNotEnough)
        }
        
        guard
            let params = oldTx.params as? BitcoinTransactionParams,
            let sequence = params.inputs.max(by: { $0.sequence < $1.sequence })?.sequence
        else {
            return .anyFail(error: BlockchainSdkError.failedToFindTxInputs)
        }
        
        //        let outputs = loadedUnspents.filter { unspent in params.inputs.contains(where: { $0.prevHash == unspent.transactionHash })}
        let outputs = loadedUnspents.filter { $0.transactionHash != transactionHash }
        txBuilder.unspentOutputs = outputs
        
        return send(newTransaction, signer: signer, sequence: sequence + 1, isPushingTx: true)
            .map { _ in Void() }
            .eraseToAnyPublisher()
    }
}

extension BitcoinWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        networkService.getSignatureCount(address: wallet.address)
            .tryMap {
                if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
            }
            .eraseToAnyPublisher()
    }
}

extension BitcoinWalletManager: ThenProcessable { }
