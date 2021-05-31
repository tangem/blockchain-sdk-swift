//
//  TransactionPusher.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/01/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk

public protocol FeeProvider {
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount],Error>
}

public protocol TransactionPusher {
    func canPushTransaction(_ transaction: Transaction) -> AnyPublisher<(Bool, [Amount]), Error>
    func pushTransaction(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error>
}

protocol DefaultTransactionPusher {
    var wallet: Wallet { get }
    var feeProvider: FeeProvider! { get }
    func canPushTx(_ tx: Transaction) -> AnyPublisher<(Bool, [Amount]), Error>
}

extension DefaultTransactionPusher {
    
    func canPushTx(_ tx: Transaction) -> AnyPublisher<(Bool, [Amount]), Error> {
        let availableBalance = wallet.amounts[.coin]?.value ?? 0 + wallet.pendingBalance
        let txAmount = tx.amount.value
        let txFee = tx.fee.value
        let txTotal = txAmount + txFee
        
        guard txTotal < availableBalance else {
            return Just((false, []))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        }
        
        return feeProvider.getFee(amount: tx.amount, destination: tx.destinationAddress, includeFee: txTotal == availableBalance)
            .map { fees -> (Bool, [Amount]) in
                let available = fees.filter {
                    $0.value > txFee &&
                        $0.value + txAmount <= availableBalance
                }
                return (available.count > 0, available)
            }
            .eraseToAnyPublisher()
    }
}
