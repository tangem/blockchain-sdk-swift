//
//  TransactionValidator.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

public protocol TransactionValidator: WalletProvider {
    func validate(amount: Amount, fee: Fee, destination: DestinationType?) async throws
    func validate(amount: Amount, fee: Fee) throws
}

public enum DestinationType: Hashable {
    case generate
    case address(String)
}

// MARK: - Default implementation

public extension TransactionValidator {
    func validate(amount: Amount, fee: Fee, destination: DestinationType?) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validateAmounts(amount: amount, fee: fee.amount)
    }
    
    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
    }
}

// MARK: - Simple sending amount validation (Amount, Fee)

public extension TransactionValidator {
    /// Method for the sending amount and fee validation
    /// Has default implementation just for checking balance and numbers
    func validateAmounts(amount: Amount, fee: Amount) throws {
        guard amount.value >= 0 else {
            throw ValidationError.invalidAmount
        }
        
        guard fee.value >= 0 else {
            throw ValidationError.invalidFee
        }
        
        guard let balance = wallet.amounts[amount.type] else {
            throw ValidationError.balanceNotFound
        }
        
        guard balance >= amount else {
            throw ValidationError.amountExceedsBalance
        }
        
        guard let feeBalance = wallet.amounts[fee.type] else {
            throw ValidationError.balanceNotFound
        }
        
        guard feeBalance >= fee else {
            throw ValidationError.feeExceedsBalance
        }
        
        // If we try to spend all amount from coin
        guard amount.type == fee.type else {
            // Safely return because all the checks were above
            return
        }
        
        let total = amount + fee
        
        guard balance >= total else {
            throw ValidationError.totalExceedsBalance
        }
        
        // All checks completed
    }
}

// MARK: - DustRestrictable

extension TransactionValidator where Self: DustRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType?) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }
    
    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
        try validateDustRestrictable(amount: amount, fee: fee.amount)
    }
}

// MARK: - MinimumBalanceRestrictable

extension TransactionValidator where Self: MinimumBalanceRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType?) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }
    
    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
        try validateMinimumBalanceRestrictable(amount: amount, fee: fee.amount)
    }
}

// MARK: - WithdrawalValidator

extension TransactionValidator where Self: WithdrawalValidator {
    func validate(amount: Amount, fee: Fee, destination: DestinationType?) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }
    
    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)

        if let withdrawalWarning = validateWithdrawalWarning(amount: amount, fee: fee.amount) {
            throw ValidationError.withdrawalWarning(withdrawalWarning)
        }
    }
}

// MARK: - DustRestrictable, WithdrawalValidator e.g. KaspaWalletManager

extension TransactionValidator where Self: WithdrawalValidator, Self: DustRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType?) async throws {
        Log.debug("TransactionValidator \(self) doesn't checking destination. If you want it, make our own implementation")
        try validate(amount: amount, fee: fee)
    }

    func validate(amount: Amount, fee: Fee) throws {
        try validateAmounts(amount: amount, fee: fee.amount)
        try validateDustRestrictable(amount: amount, fee: fee.amount)
        
        if let withdrawalWarning = validateWithdrawalWarning(amount: amount, fee: fee.amount) {
            throw ValidationError.withdrawalWarning(withdrawalWarning)
        }
    }
}

// MARK: - ReserveAmountRestrictable

extension TransactionValidator where Self: ReserveAmountRestrictable {
    func validate(amount: Amount, fee: Fee, destination: DestinationType?) async throws {
        try validateAmounts(amount: amount, fee: fee.amount)

        switch destination {
        case .none:
            try validateAmounts(amount: amount, fee: fee.amount)
        case .generate:
            try await validateReserveAmountRestrictable(amount: amount, addressType: .new)
        case .address(let string):
            try await validateReserveAmountRestrictable(amount: amount, addressType: .address(string))
        }
    }
}
