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

class BitcoinWalletManager: WalletManager {
    var allowsFeeSelection: Bool { true }
    var txBuilder: BitcoinTransactionBuilder!
    var networkService: BitcoinNetworkProvider!
    
    var minimalFeePerByte: Decimal { 10 }
    var minimalFee: Decimal { 0.00001 }
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void)  {
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
    
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .tryMap {[unowned self] response throws -> [Amount] in
              //  let dummyFee = Amount(with: amount, value: 0.00000001)
                var minRate = (max(response.minimalSatoshiPerByte, self.minimalFeePerByte) as NSDecimalNumber).intValue
                var normalRate = (max(response.normalSatoshiPerByte, self.minimalFeePerByte * 1.2) as NSDecimalNumber).intValue
                var maxRate = (max(response.prioritySatoshiPerByte, self.minimalFeePerByte * 1.5) as NSDecimalNumber).intValue
                
                var minFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: minRate, senderPay: false, changeScript: nil, isReplacedByFee: false)
                var normalFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: normalRate, senderPay: false, changeScript: nil, isReplacedByFee: false)
                var maxFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: maxRate, senderPay: false, changeScript: nil, isReplacedByFee: false)
                
                if minFee < self.minimalFee {
                    minRate = ((self.minimalFee/minFee).rounded(scale: 0, roundingMode: .down) as NSDecimalNumber).intValue
                    minFee = self.minimalFee
                }
                
                if normalFee < self.minimalFee {
                    normalRate = ((self.minimalFee/normalFee).rounded(scale: 0, roundingMode: .down) as NSDecimalNumber).intValue
                    normalFee = self.minimalFee
                }
                
                if maxFee < self.minimalFee {
                    maxRate = ((self.minimalFee/maxFee).rounded(scale: 0, roundingMode: .down) as NSDecimalNumber).intValue
                    maxFee = self.minimalFee
                }
                
                txBuilder.feeRates = [:]
                txBuilder.feeRates[minFee] = minRate
                txBuilder.feeRates[normalFee] = normalRate
                txBuilder.feeRates[maxFee] = maxRate
                return [
                    Amount(with: self.wallet.blockchain, address: self.wallet.address, value: minFee),
                    Amount(with: self.wallet.blockchain, address: self.wallet.address, value: normalFee),
                    Amount(with: self.wallet.blockchain, address: self.wallet.address, value: maxFee)
                ]
        }
        .eraseToAnyPublisher()
    }
    
    func updateWallet(with response: [BitcoinResponse]) {
        let balance = response.reduce(into: 0) { $0 += $1.balance }
        let hasUnconfirmed = response.contains(where: { $0.hasUnconfirmed })
        let unspents = response.flatMap { $0.txrefs }
        
        wallet.add(coinValue: balance)
        txBuilder.unspentOutputs = unspents
        if hasUnconfirmed {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
            }
        } else {
            wallet.transactions = []
        }
    }
    
//    private func getEstimateSize(for transaction: Transaction) -> Decimal? {
//        guard let unspentOutputsCount = txBuilder.unspentOutputs?.count else {
//            return nil
//        }
//
//        guard let tx = txBuilder.buildForSend(transaction: transaction, signature: Data(repeating: UInt8(0x80), count: 64 * unspentOutputsCount)) else {
//            return nil
//        }
//
//        return Decimal(tx.count)
//    }
}


extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard let hashes = txBuilder.buildForSign(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: hashes, cardId: wallet.cardId, walletPublicKey: wallet.publicKey)
            .tryMap {[unowned self] signatures -> (String) in
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signatures: signatures) else {
                    throw WalletError.failedToBuildTx
                }
                return tx.toHexString()
        }
        .flatMap {[unowned self] tx -> AnyPublisher<Void, Error> in
            return self.networkService.send(transaction: tx)
                .map {[unowned self] sendResponse in
                    self.wallet.add(transaction: transaction)
            }.eraseToAnyPublisher()
        }
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

