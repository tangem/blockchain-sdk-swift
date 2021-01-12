//
//  TransactionPusher.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/01/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine

public protocol FeeProvider {
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount],Error>
}

public protocol TransactionPusher {
    var wallet: Wallet { get }
    var feeProvider: FeeProvider! { get }
    func canPushTransaction(_ transaction: Transaction) -> AnyPublisher<Bool, Error>
}

extension TransactionPusher {
    func canPushTransaction(_ transaction: Transaction) -> AnyPublisher<Bool, Error> {
        let availableBalance = wallet.amounts[.coin]?.value ?? 0 + wallet.pendingBalance
        let txAmount = transaction.amount.value
        let txFee = transaction.fee.value
        let txTotal = txAmount + txFee
        
        guard txTotal < availableBalance else {
            return Just(false)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
            
        }
        
        return feeProvider.getFee(amount: transaction.amount, destination: transaction.destinationAddress, includeFee: txTotal == availableBalance)
            .map { fees -> Bool in
                fees.filter {
                    $0.value > txFee &&
                        $0.value + txAmount <= availableBalance
                }.count > 0
            }
            .eraseToAnyPublisher()
    }
}
