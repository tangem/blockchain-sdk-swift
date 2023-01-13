//
//  BaseManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 05.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
class BaseManager: WalletProvider {
    @Published var wallet: Wallet
    var cardTokens: [Token] = []
    
    var defaultSourceAddress: String { wallet.address }
    var defaultChangeAddress: String { wallet.address }
    
    var cancellable: Cancellable? = nil
    var walletPublisher: Published<Wallet>.Publisher { $wallet }

    init(wallet: Wallet) {
        self.wallet = wallet
    }
    
    func removeToken(_ token: Token) {
        cardTokens.removeAll(where: { $0 == token })
        wallet.remove(token: token)
    }
    
    func addToken(_ token: Token) {
        if !cardTokens.contains(token) {
            cardTokens.append(token)
        }
    }
    
    func addTokens(_ tokens: [Token]) {
        tokens.forEach { addToken($0) }
    }
}

// MARK: - TransactionCreator

extension BaseManager: TransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Amount,
        sourceAddress: String? = nil,
        destinationAddress: String,
        changeAddress: String? = nil,
        contractAddress: String? = nil,
        date: Date = Date(),
        status: TransactionStatus = .unconfirmed
    ) throws -> Transaction {
        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress ?? defaultSourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress ?? defaultChangeAddress,
            contractAddress: contractAddress ?? amount.type.token?.contractAddress,
            date: date,
            status: status,
            hash: nil
        )
        
        try validateTransaction(amount: amount, fee: fee)
        return transaction
    }
    
    func validate(amount: Amount) throws {
        if !validateAmountValue(amount) {
            throw TransactionError.invalidAmount
        }
        
        if !validateAmountTotal(amount) {
            throw TransactionError.amountExceedsBalance
        }
    }
    
    func validate(fee: Amount) throws {
        if !validateAmountValue(fee) {
            throw TransactionError.invalidFee
        }
        
        if !validateAmountTotal(fee) {
            throw TransactionError.feeExceedsBalance
        }
    }
}

// MARK: - Validation

private extension BaseManager {
    func validateTransaction(amount: Amount, fee: Amount?) throws {
        var errors = [TransactionError]()
        
        do {
            try validate(amount: amount)
        } catch let error as TransactionError {
            errors.append(error)
        }
        
        guard let fee = fee else {
            throw TransactionErrors(errors: errors)
        }
        
        do {
            try validate(fee: fee)
        } catch let error as TransactionError {
            errors.append(error)
        }
                
        let total = amount + fee
        
        if amount.type == fee.type,
           total.value > 0,
            (try? validate(amount: total)) != nil {
            errors.append(.totalExceedsBalance)
        }
        
        if let dustAmount = (self as? DustRestrictable)?.dustValue {
            if amount < dustAmount {
                errors.append(.dustAmount(minimumAmount: dustAmount))
            }
            
            if let walletAmount = wallet.amounts[dustAmount.type] {
                let change = walletAmount - total
                if change.value != 0 && change < dustAmount {
                    errors.append(.dustChange(minimumAmount: dustAmount))
                }
            }
        }
        
        if let minimumBalanceRestrictable = self as? MinimumBalanceRestrictable,
           let walletAmount = wallet.amounts[amount.type],
           case .coin = amount.type
        {
            let remainderBalance = walletAmount - total
            if remainderBalance < minimumBalanceRestrictable.minimumBalance && !remainderBalance.isZero {
                errors.append(.minimumBalance(minimumBalance: minimumBalanceRestrictable.minimumBalance))
            }
        }
        
        if !errors.isEmpty {
            throw TransactionErrors(errors: errors)
        }
    }
    
    func validateAmountValue(_ amount: Amount) -> Bool {
        return amount.value >= 0
    }
    
    func validateAmountTotal(_ amount: Amount) -> Bool {
        let total = wallet.amounts[amount.type] ?? Amount(with: amount, value: 0)
        
        guard total >= amount else {
            return false
        }
        
        return true
    }
}
