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
    var wallet: Wallet {
        get { _wallet.value }
        set { _wallet.value = newValue }
    }
    
    var cardTokens: [Token] = []
    
    var defaultSourceAddress: String { wallet.address }
    var defaultChangeAddress: String { wallet.address }

    var cancellable: Cancellable? = nil

    var walletPublisher: AnyPublisher<Wallet, Never> { _wallet.eraseToAnyPublisher() }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { state.eraseToAnyPublisher() }

    private var latestUpdateTime: Date?

    // TODO: move constant into config
    private var canUpdate: Bool {
        if let latestUpdateTime,
           latestUpdateTime.distance(to: Date()) <= 10 {
            return false
        }

        return true
    }

    private var _wallet: CurrentValueSubject<Wallet, Never>
    private var state: CurrentValueSubject<WalletManagerState, Never> = .init(.initial)
    private var loadingPublisher: PassthroughSubject<WalletManagerState, Never> = .init()

    init(wallet: Wallet) {
        self._wallet = .init(wallet)
    }

    func update() {
        if state.value.isLoading {
            return
        }

        guard canUpdate else {
            didFinishUpdating(error: nil)
            return
        }

        state.send(.loading)

        update { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                self.didFinishUpdating(error: nil)
                self.latestUpdateTime = Date()
            case .failure(let error):
                self.didFinishUpdating(error: error)
            }
        }
    }

    func update(completion: @escaping (Result<Void, Error>) -> Void) {}

    func setNeedsUpdate() {
        latestUpdateTime = nil
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

    func updatePublisher() -> AnyPublisher<WalletManagerState, Never> {
        if !state.value.isLoading {
            // we should postpone an update call to prevent missing a cached value by PassthroughSubject
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                self.update()
            }
        }

        return loadingPublisher.eraseToAnyPublisher()
    }

    private func didFinishUpdating(error: Error?) {
        var newState: WalletManagerState

        if let error {
            newState = .failed(error)
        } else {
            newState = .loaded
        }

        state.send(newState)
        loadingPublisher.send(newState)
    }
}

// MARK: - TransactionCreator

extension BaseManager: TransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        sourceAddress: String? = nil,
        destinationAddress: String,
        changeAddress: String? = nil,
        contractAddress: String? = nil
    ) throws -> Transaction {
        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress ?? defaultSourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: changeAddress ?? defaultChangeAddress,
            contractAddress: contractAddress ?? amount.type.token?.contractAddress
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
    
    func validate(fee: Fee) throws {
        if !validateAmountValue(fee.amount) {
            throw TransactionError.invalidFee
        }
        
        if !validateAmountTotal(fee.amount) {
            throw TransactionError.feeExceedsBalance
        }
    }
}

// MARK: - Validation

private extension BaseManager {
    func validateTransaction(amount: Amount, fee: Fee?) throws {
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
                
        let total = amount + fee.amount
        
        var totalError: TransactionError?
        do {
            try validate(amount: total)
        } catch let error as TransactionError {
            totalError = error
        }

        if amount.type == fee.amount.type, total.value > 0, totalError != nil {
            errors.append(.totalExceedsBalance)
        }
        
        if let dustAmount = (self as? DustRestrictable)?.dustValue {
            if amount.type == dustAmount.type, amount < dustAmount {
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
