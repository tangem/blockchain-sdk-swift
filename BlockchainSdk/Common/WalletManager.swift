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
    
    @Published public var wallet: Wallet
    
    var cancellable: Cancellable? = nil
    
    init(cardId: String, wallet: Wallet) {
        self.cardId = cardId
        self.wallet = wallet
    }
    
    public func update(completion: @escaping (Result<(), Error>)-> Void) {
        fatalError("You should override this method")
    }
    
    public func createTransaction(amount: Amount, fee: Amount, destinationAddress: String) -> Result<Transaction,TransactionError> {
        let transaction = Transaction(amount: amount,
                                      fee: fee,
                                      sourceAddress: wallet.address,
                                      destinationAddress: destinationAddress,
                                      contractAddress: wallet.token?.contractAddress,
                                      date: Date(),
                                      status: .unconfirmed,
                                      hash: nil)
        
        let validationResult = validateTransaction(amount: amount, fee: fee)
        if validationResult.isEmpty {
            return .success(transaction)
        } else {
            return .failure(validationResult)
        }
    }
    
    func validateTransaction(amount: Amount, fee: Amount?) -> TransactionError {
        var errors = TransactionError()
        
        if !validate(amount: amount) {
            errors.update(with: .wrongAmount)
        }
        
        guard let fee = fee else {
            return errors
        }
        
        if !validate(amount: fee) {
           errors.update(with: .wrongFee)
        }
        
        if amount.type == fee.type,
            !validate(amount: Amount(with: amount, value: amount.value + fee.value)) {
           errors.update(with: .wrongTotal)
        }
        
        return errors
    }
    
    public func validate(amount: Amount) -> Bool {
        guard amount.value > 0,
            let total = wallet.amounts[amount.type]?.value, total >= amount.value else {
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



