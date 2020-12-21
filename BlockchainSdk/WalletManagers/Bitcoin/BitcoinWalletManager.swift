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
    var relayFee: Decimal? {
        return nil
    }
    
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
    
    @available(iOS 13.0, *)
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .tryMap {[unowned self] response throws -> [Amount] in
              //  let dummyFee = Amount(with: amount, value: 0.00000001)
                var minRate = max((response.minimalSatoshiPerByte as NSDecimalNumber).intValue, 1)
                var normalRate = max((response.normalSatoshiPerByte as NSDecimalNumber).intValue, 1)
                var maxRate = max((response.prioritySatoshiPerByte as NSDecimalNumber).intValue, 1)
                
                var minFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: minRate, senderPay: !includeFee, changeScript: nil)
                var normalFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: normalRate, senderPay: !includeFee, changeScript: nil)
                var maxFee = txBuilder.bitcoinManager.fee(for: amount.value, address: destination, feeRate: maxRate, senderPay: !includeFee, changeScript: nil)
                
                
                
                
                
//                guard let estimatedTxSize = self.getEstimateSize(for: Transaction(amount: amount - dummyFee,
//                                                                                  fee: dummyFee,
//                                                                                  sourceAddress: self.wallet.address,
//                                                                                  destinationAddress: destination,
//                                                                                  changeAddress: self.wallet.address)) else {
//                    throw WalletError.failedToCalculateTxSize
//                }
//
//                var minFee = (minPerByte * estimatedTxSize)
//                var normalFee = (normalPerByte * estimatedTxSize)
//                var maxFee = (maxPerByte * estimatedTxSize)
//
                if let relayFee = self.relayFee {
                    if minFee < relayFee {
                        minRate = ((relayFee/minFee).rounded(scale: 0, roundingMode: .down) as NSDecimalNumber).intValue
                        minFee = relayFee
                    }
                    
                    if normalFee < relayFee {
                        normalRate = ((relayFee/normalFee).rounded(scale: 0, roundingMode: .down) as NSDecimalNumber).intValue
                        normalFee = relayFee
                    }
                    
                    if maxFee < relayFee {
                        maxRate = ((relayFee/maxFee).rounded(scale: 0, roundingMode: .down) as NSDecimalNumber).intValue
                        maxFee = relayFee
                    }
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


@available(iOS 13.0, *)
extension BitcoinWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        guard let hashes = txBuilder.buildForSign(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hashes: hashes, cardId: cardId)
            .tryMap {[unowned self] response -> (String, SignResponse) in
                guard let tx = self.txBuilder.buildForSend(transaction: transaction, signature: response.signature, hashesCount: hashes.count) else {
                    throw WalletError.failedToBuildTx
                }
                return (tx.toHexString(), response)
        }
        .flatMap {[unowned self] values -> AnyPublisher<SignResponse, Error> in
            return self.networkService.send(transaction: values.0)
                .map {[unowned self] sendResponse in
                    self.wallet.add(transaction: transaction)
                    return values.1
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

