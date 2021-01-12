//
//  Transaction.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol TransactionParams {}

public struct Transaction: Equatable {
    public static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        if lhs.hash != nil && rhs.hash != nil {
            return lhs.hash == rhs.hash
        }
        
        return lhs.amount == rhs.amount &&
            lhs.fee == rhs.fee &&
            lhs.sourceAddress == rhs.sourceAddress &&
            lhs.destinationAddress == rhs.destinationAddress &&
            lhs.changeAddress == rhs.changeAddress &&
            lhs.date == rhs.date &&
            lhs.status == rhs.status
    }
    
    public let amount: Amount
    public let fee: Amount
    public let sourceAddress: String
    public let destinationAddress: String
    public let changeAddress: String
    public let contractAddress: String?
    public internal(set) var date: Date? = nil
    public internal(set) var status: TransactionStatus = .unconfirmed
    public internal(set) var hash: String? = nil
    public var params: TransactionParams? = nil
    
    internal init(amount: Amount, fee: Amount,
                  sourceAddress: String,
                  destinationAddress: String,
                  changeAddress: String,
                  contractAddress: String? = nil,
                  date: Date? = nil,
                  status: TransactionStatus = .unconfirmed,
                  hash: String? = nil) {
        self.amount = amount
        self.fee = fee
        self.sourceAddress = sourceAddress
        self.destinationAddress = destinationAddress
        self.changeAddress = changeAddress
        self.contractAddress = contractAddress
        self.date = date
        self.status = status
        self.hash = hash
    }
}

public enum TransactionStatus: Equatable {
    case unconfirmed
    case confirmed
}

public struct TransactionErrors: Error {
    public let errors: [TransactionError]
}

public enum TransactionError: Error, LocalizedError {
    case invalidAmount
    case amountExceedsBalance
    case invalidFee
    case feeExceedsBalance
    case totalExceedsBalance
    case dustAmount(minimumAmount: Amount)
    case dustChange(minimumAmount: Amount)
        
    public var errorDescription: String? {
        switch self {
        case .amountExceedsBalance:
            return "send_validation_amount_exceeds_balance".localized
        case .dustAmount(let minimumAmount):
            return String(format: "send_error_dust_amount_format".localized, minimumAmount.description)
        case .dustChange(let minimumAmount):
           return String(format: "send_error_dust_change_format".localized, minimumAmount.description)
        case .feeExceedsBalance:
            return "send_validation_invalid_fee".localized
        case .invalidAmount:
            return "send_validation_invalid_amount".localized
        case .invalidFee:
            return "send_error_invalid_fee_value".localized
        case .totalExceedsBalance:
            return "send_validation_invalid_total".localized
        }
    }
}


protocol DustRestrictable {
    var dustValue: Amount { get }
}
