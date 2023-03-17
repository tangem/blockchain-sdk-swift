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

@available(iOS 13.0, *)
public protocol WalletManager: WalletProvider, BlockchainDataProvider, TransactionSender, TransactionCreator, TransactionFeeProvider {
    var cardTokens: [Token] { get }
    func update(completion: @escaping (Result<Void, Error>) -> Void)
    func updatePublisher() -> AnyPublisher<Wallet, Error>
    
    func removeToken(_ token: Token)
    func addToken(_ token: Token)
    func addTokens(_ tokens: [Token])
}

extension WalletManager {
    func updatePublisher() -> AnyPublisher<Wallet, Error> {
        Deferred {
            Future { promise in
                self.update { result in
                    switch result {
                    case .success:
                        promise(.success(self.wallet))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
public protocol WalletProvider: AnyObject {
    var wallet: Wallet { get set }
    var walletPublisher: Published<Wallet>.Publisher { get }
}

public protocol BlockchainDataProvider {
    var currentHost: String { get }
    var outputsCount: Int? { get }
}

extension BlockchainDataProvider {
    var outputsCount: Int? { return nil }
}

@available(iOS 13.0, *)
public protocol TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error>
}

@available(iOS 13.0, *)
public protocol TransactionFeeProvider {
    var allowsFeeSelection: Bool { get }
    func getFee(amount: Amount, destination: String) -> AnyPublisher<FeeType, Error>
}

public struct SendTxError: Error, LocalizedError {
    public let error: Error
    public let tx: String
    
    public var errorDescription: String? {
        error.localizedDescription
    }
}

@available(iOS 13.0, *)
public protocol TransactionSigner {
    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error>
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error>
}

@available(iOS 13.0, *)
public protocol TransactionPusher {
    func isPushAvailable(for transactionHash: String) -> Bool
    func getPushFee(for transactionHash: String) -> AnyPublisher<FeeType, Error>
    func pushTransaction(with transactionHash: String, newTransaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error>
}

@available(iOS 13.0, *)
public protocol SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error>
}

public protocol WithdrawalValidator {
    func validate(_ transaction: Transaction) -> WithdrawalWarning?
}

public protocol TokenFinder {
    func findErc20Tokens(knownTokens: [Token], completion: @escaping (Result<Bool, Error>)-> Void)
}

public struct WithdrawalWarning {
    public let warningMessage: String
    public let reduceMessage: String
    public let ignoreMessage: String
    public let suggestedReduceAmount: Amount
}

public protocol RentProvider {
    func minimalBalanceForRentExemption() -> AnyPublisher<Amount, Error>
    func rentAmount() -> AnyPublisher<Amount, Error>
}

public protocol ExistentialDepositProvider {
    var existentialDeposit: Amount { get }
}
