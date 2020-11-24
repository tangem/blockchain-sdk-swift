//
//  Walletmanager.swift
//  blockchainSdk
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

public enum WalletError: Error, LocalizedError {
    case noAccount(message: String)
    case failedToGetFee
    case failedToBuildTx
    case failedToParseNetworkResponse
    case failedToSendTx
    case failedToCalculateTxSize
    
    public var errorDescription: String? {
        switch self {
        case .noAccount(let message):
            return message
        case .failedToGetFee:
            return "common_fee_error".localized
        case .failedToBuildTx:
            return "common_build_tx_error".localized
        case .failedToParseNetworkResponse:
            return "common_parse_network_response_error".localized
        case .failedToSendTx:
            return "common_send_tx_error".localized
        case .failedToCalculateTxSize:
            return "common_estimate_tx_size_error".localized
        }
    }
    
}


public class WalletManager {
    public let cardId: String
    public let cardTokens: [Token]
    @Published public var wallet: Wallet
    
    var defaultSourceAddress: String { wallet.address }
    var defaultChangeAddress: String { wallet.address }    
    var cancellable: Cancellable? = nil

    
    init(cardId: String, wallet: Wallet, cardTokens: [Token] = []) {
        self.cardId = cardId
        self.wallet = wallet
        self.cardTokens = cardTokens
    }
    
    public func update(completion: @escaping (Result<(), Error>)-> Void) {
        fatalError("You should override this method")
    }
    
    public func createTransaction(amount: Amount,
                                  fee: Amount,
                                  destinationAddress: String,
                                  sourceAddress: String? = nil,
                                  changeAddress: String? = nil) -> Result<Transaction,TransactionErrors> {
        let transaction = Transaction(amount: amount,
                                      fee: fee,
                                      sourceAddress: sourceAddress ?? defaultSourceAddress,
                                      destinationAddress: destinationAddress,
                                      changeAddress: changeAddress ?? defaultChangeAddress,
                                      contractAddress: amount.type.token?.contractAddress,
                                      date: Date(),
                                      status: .unconfirmed,
                                      hash: nil)
        
        let validationResult = validateTransaction(amount: amount, fee: fee)
        if validationResult.errors.isEmpty {
            return .success(transaction)
        } else {
            return .failure(validationResult)
        }
    }
    
    
    public func validate(amount: Amount) -> TransactionError? {
        if !validateAmountValue(amount) {
            return .invalidAmount
        }
        
        if !validateAmountTotal(amount) {
            return .amountExceedsBalance
        }
        
        return nil
    }
    
    public func validate(fee: Amount) -> TransactionError? {
        if !validateAmountValue(fee) {
            return .invalidFee
        }
        
        if !validateAmountTotal(fee) {
            return .feeExceedsBalance
        }
        
        return nil
    }
    
    func validateTransaction(amount: Amount, fee: Amount?) -> TransactionErrors {
        var errors = [TransactionError]()
        
        if let amountError = validate(amount: amount) {
            errors.append(amountError)
        }
        
        guard let fee = fee else {
            return TransactionErrors(errors: errors)
        }
        
        if let feeError = validate(fee: fee) {
            errors.append(feeError)
        }
        
        let total = amount + fee
        
        if amount.type == fee.type,
            validate(amount: total) != nil {
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
        
        return TransactionErrors(errors: errors)
    }
    
    private func validateAmountValue(_ amount: Amount) -> Bool {
        return amount.value > 0
    }
    
    private func validateAmountTotal(_ amount: Amount) -> Bool {
        guard let total = wallet.amounts[amount.type],
            total >= amount else {
            return false
        }
        
        return true
    }
}

@available(iOS 13.0, *)
public protocol TransactionSender {
    var allowsFeeSelection: Bool {get}
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error>
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error>
}

@available(iOS 13.0, *)
public protocol TransactionSigner {
    func sign(hashes: [Data], cardId: String) -> AnyPublisher<SignResponse, Error>
}


public protocol WithdrawalValidator {
    func validate(_ transaction: Transaction) -> WithdrawalWarning?
}

public struct WithdrawalWarning {
    public let warningMessage: String
    public let reduceMessage: String
    public let ignoreMessage: String
    public let suggestedReduceAmount: Amount
}
