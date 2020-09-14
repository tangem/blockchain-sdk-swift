//
//  XRPWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class XRPWalletManager: WalletManager {
    var txBuilder: XRPTransactionBuilder!
    var networkService: XRPNetworkService!
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(account: wallet.address)
            .sink(receiveCompletion: { completionSubscription in
                if case let .failure(error) = completionSubscription {
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    private func updateWallet(with response: XrpInfoResponse) {
        wallet.add(reserveValue: response.reserve/Decimal(1000000))
        wallet.add(coinValue: (response.balance - response.reserve)/Decimal(1000000))
        
        txBuilder.account = wallet.address
        txBuilder.sequence = response.sequence
        if response.balance != response.unconfirmedBalance {
            if wallet.transactions.isEmpty {
                wallet.addPendingTransaction()
            }
        } else {
            wallet.transactions = []
        }
    }
}

@available(iOS 13.0, *)
extension XRPWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Bool, Error> {
        guard let walletReserve = wallet.amounts[.reserve]?.value,
            let hashToSign = txBuilder.buildForSign(transaction: transaction) else {
                return Fail(error: "Missing reserve").eraseToAnyPublisher()
        }
        
        return networkService
            .checkAccountCreated(account: transaction.sourceAddress)
            .tryMap{ isAccountCreated in
                if !isAccountCreated && transaction.amount.value < walletReserve {
                    throw "Target account is not created. Amount to send should be \(walletReserve) XRP + fee or more"
                }
        }
        .flatMap{[unowned self] in
            return signer.sign(hashes: [hashToSign], cardId: self.cardId)
        }
        .tryMap{[unowned self] response -> String in
            guard let tx = self.txBuilder.buildForSend(transaction: transaction, signature: response.signature) else {
                throw "Failed to build transaction"
            }
            
            return tx
        }
        .flatMap{[unowned self] builderResponse in
            self.networkService.send(blob: builderResponse)
                .map{[unowned self] response in
                    self.wallet.add(transaction: transaction)
                    return true
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .map { xrpFeeResponse -> [Amount] in
                let min = xrpFeeResponse.min/Decimal(1000000)
                let normal = xrpFeeResponse.normal/Decimal(1000000)
                let max = xrpFeeResponse.max/Decimal(1000000)
                
                let minAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: min)
                let normalAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: normal)
                let maxAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: max)
                return [minAmount, normalAmount, maxAmount]
        }
        .eraseToAnyPublisher()
    }
}

extension XRPWalletManager: ThenProcessable { }
