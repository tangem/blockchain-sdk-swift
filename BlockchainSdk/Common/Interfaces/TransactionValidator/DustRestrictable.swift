//
//  DustRestrictable.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol DustRestrictable {
    var dustValue: Amount { get }

    func validateDustRestrictable(amount: Amount, fee: Amount) throws
}

extension DustRestrictable where Self: WalletProvider {
    func validateDustRestrictable(amount: Amount, fee: Amount) throws {
        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }
        
        // This check is first that exclude case below
        // Checking if sending a small total (amount + fee)
        if amount.type == dustValue.type, fee.type == dustValue.type {
            let total = amount + fee
            if total < dustValue {
                throw ValidationError.dustAmount(minimumAmount: dustValue)
            }
            
            let change = balance - total
            if change.value > 0, change < dustValue {
                throw ValidationError.dustChange(minimumAmount: dustValue)
            }
        // Checking if sending a small amount or token's balance will be small after sent
        } else if dustValue.type == amount.type {
            if amount < dustValue {
                throw ValidationError.dustAmount(minimumAmount: dustValue)
            }
            
            let change = balance - amount
            if change.value > 0, change < dustValue {
                throw ValidationError.dustChange(minimumAmount: dustValue)
            }
        }
    }
    
}
