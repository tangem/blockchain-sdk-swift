//
//  KaspaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaWalletManager: BaseManager, WalletManager {
    var txBuilder: KaspaTransactionBuilder!
    var networkService: KaspaNetworkService!
    
    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool { false }
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService.getInfo(address: wallet.address)
            .sink { result in
                switch result {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] response in
                self?.updateWallet(response)
            }
    }
    
    func updateWallet(_ response: BitcoinResponse) {
        self.wallet.add(amount: Amount(with: self.wallet.blockchain, value: response.balance))
        txBuilder.unspentOutputs = response.unspentOutputs
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        //        txBuilder.buildForSend(transaction)
//        let (kaspaTransaction, hashes) = txBuilder.buildForSign(transaction)
//
//
//        return signer.sign(hashes: hashes,
//                           walletPublicKey: self.wallet.publicKey)
//        .tryMap { [weak self] signatures in
//            guard let self = self else { throw WalletError.empty }
//
//            return self.txBuilder.buildForSend(transaction: kaspaTransaction, signatures: signatures)
//        }
//        .flatMap {[weak self] tx -> AnyPublisher<TransactionSendResult, Error> in
//            guard let self = self else { return .emptyFail }
//
////            let txHashPublisher: AnyPublisher<String, Error>
////            if isPushingTx {
////                txHashPublisher = self.networkService.push(transaction: tx)
////            } else {
////                txHashPublisher = self.networkService.send(transaction: tx)
////            }
//            self.networkService.send(transaction: <#T##String#>)
//
////            return txHashPublisher.tryMap {[weak self] sendResponse in
////                guard let self = self else { throw WalletError.empty }
////
////                var sendedTx = transaction
////                sendedTx.hash = sendResponse
////                self.wallet.add(transaction: sendedTx)
////                return TransactionSendResult(hash: sendResponse)
////            }
////            .mapError { SendTxError(error: $0, tx: tx) }
////            .eraseToAnyPublisher()
//        }
//        .eraseToAnyPublisher()
        
        return .anyFail(error: WalletError.empty)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        Just([Amount.zeroCoin(for: wallet.blockchain)])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

extension KaspaWalletManager: ThenProcessable { }
