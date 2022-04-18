//
//  TronWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class TronWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        fatalError()
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    var networkService: TronNetworkService!
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService.getAccount(for: wallet.address)
            .sink {
                switch $0 {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
                print($0)
            } receiveValue: { [unowned self] in
                print($0)
                self.updateWallet($0)
            }
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        let decimalAmount = transaction.amount.value * wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value

        return networkService.createTransaction(from: transaction.sourceAddress, to: transaction.destinationAddress, amount: intAmount)
            .flatMap { request -> AnyPublisher<TronTransactionRequest, Error> in
                self.sign(request, with: signer)
            }
            .flatMap { transaction in
                self.networkService.broadcastTransaction(transaction)
            }
            .map({ res -> Void in // weak self
                print(res)
                return ()
            })
            .eraseToAnyPublisher()
    }
    
    func sign(_ transaction: TronTransactionRequest, with signer: TransactionSigner) -> AnyPublisher<TronTransactionRequest, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap { _ -> AnyPublisher<Data, Error> in // weak self
                let rawData = Data(hex: transaction.raw_data_hex)
                let hash = rawData.sha256()
                return signer.sign(hash: hash, cardId: self.wallet.cardId, walletPublicKey: self.wallet.publicKey)
            }
            .map({ signature -> TronTransactionRequest in
                var newTransaction = transaction
                newTransaction.signature = [signature.hexString]
                return newTransaction
            })
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        .anyFail(error: WalletError.empty)
    }
    
    private func updateWallet(_ response: TronGetAccountResponse) {
        let blockchain = wallet.blockchain
        wallet.add(amount: Amount(with: blockchain, value: Decimal(response.balance) / blockchain.decimalValue))
    }
}

extension TronWalletManager: ThenProcessable {

}
