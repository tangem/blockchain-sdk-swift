//
//  CardanoWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

public enum CardanoError: String, Error, LocalizedError {
    case noUnspents = "cardano_missing_unspents"
    case lowAda = "cardano_low_ada"
     
    public var errorDescription: String? {
        return self.rawValue.localized
    }
}

class CardanoWalletManager: BaseManager, WalletManager {
    var txBuilder: CardanoTransactionBuilder!
    var networkService: CardanoNetworkProvider!
    
    var currentHost: String { networkService.host }
    
    func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(addresses: wallet.addresses.map { $0.value })
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
    
    private func updateWallet(with response: CardanoAddressResponse) {
        wallet.add(coinValue: response.balance)
        txBuilder.unspentOutputs = response.unspentOutputs
        
        wallet.transactions = wallet.transactions.map {
            var mutableTx = $0
            let hashLowercased = mutableTx.hash?.lowercased()
            if response.recentTransactionsHashes.isEmpty {
                if response.unspentOutputs.isEmpty ||
                    response.unspentOutputs.first(where: { $0.transactionHash.lowercased() == hashLowercased }) != nil {
                    mutableTx.status = .confirmed
                }
            } else {
                if response.recentTransactionsHashes.first(where: { $0.lowercased() == hashLowercased }) != nil {
                    mutableTx.status = .confirmed
                }
            }
            return mutableTx
        }
    }
}

extension CardanoWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        guard let walletAmount = wallet.amounts[.coin]?.value else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        do {
            let info = try txBuilder.buildForSign(transaction: transaction, walletAmount: walletAmount, isEstimated: false)
            
            return signer.sign(hash: info.hash,
                               walletPublicKey: self.wallet.publicKey)
                .tryMap {[weak self] signature -> (tx: Data, hash: String) in
                    guard let self = self else { throw WalletError.empty }
                    
                    let tx = try self.txBuilder.buildForSend(bodyItem: info.bodyItem, signature: signature)
                    return (tx, info.hash.hexString)
            }
            .flatMap {[weak self] builderResponse -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(transaction: builderResponse.tx).tryMap {[weak self] response in
                    guard let self = self else { throw WalletError.empty }
                    
                    var sendedTx = transaction
                    sendedTx.hash = builderResponse.hash
                    self.wallet.add(transaction: sendedTx)

                    return TransactionSendResult(hash: builderResponse.hash)
                }
                .mapError { SendTxError(error: $0, tx: builderResponse.tx.hexString) }
                .eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
            
        } catch {
            return .anyFail(error: error)
        }
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<FeeDataModel, Error> {
        guard let transactionSize = self.getEstimateSize(amount: amount, destination: destination) else {
            return Fail(error: WalletError.failedToCalculateTxSize).eraseToAnyPublisher()
        }
        
        let a = Decimal(0.155381)
        let b = Decimal(0.000044)
        
        let feeValue = (a + b * transactionSize).rounded(scale: wallet.blockchain.decimalCount, roundingMode: .up)
        let feeAmount = Amount(with: self.wallet.blockchain, value: feeValue)
        let feeDataModel = FeeDataModel(feeType: .single(fee: feeAmount))
        return Result.Publisher(feeDataModel).eraseToAnyPublisher()
    }
    
    private func getEstimateSize(amount: Amount, destination: String) -> Decimal? {
        let dummyFee = Amount(with: self.wallet.blockchain, value: Decimal(0.1))
        let dummyAmount = amount - dummyFee
        let dummyTx = Transaction(amount: dummyAmount,
                                  fee: dummyFee,
                                  sourceAddress: self.wallet.address,
                                  destinationAddress: destination,
                                  changeAddress: self.wallet.address)
        
        
        guard let walletAmount = wallet.amounts[.coin]?.value else {
            return nil
        }
        
		guard let info = try? txBuilder.buildForSign(transaction: dummyTx, walletAmount: walletAmount, isEstimated: true),
              let tx = try? txBuilder.buildForSend(bodyItem: info.bodyItem, signature: Data(repeating: 0, count: 64)) else {
            return nil
        }

        return Decimal(tx.count)
    }
}

extension CardanoWalletManager: ThenProcessable { }


extension CardanoWalletManager: DustRestrictable {
    var dustValue: Amount {
        return Amount(with: wallet.blockchain, value: 1.0)
    }
}
