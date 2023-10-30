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
    func update()
    func updatePublisher() -> AnyPublisher<WalletManagerState, Never>
    func setNeedsUpdate()
    func removeToken(_ token: Token)
    func addToken(_ token: Token)
    func addTokens(_ tokens: [Token])
}

@available(iOS 13.0, *)
public enum WalletManagerState {
    case initial
    case loading
    case loaded(Wallet)
    case failed(Error)

    public var isInitialState: Bool {
        switch self {
        case .initial:
            return true
        default:
            return false
        }
    }

    public var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
}

@available(iOS 13.0, *)
public protocol WalletProvider: AnyObject {
    var wallet: Wallet { get set }
    var walletPublisher: AnyPublisher<Wallet, Never> { get }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { get }
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
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error>
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
    func getPushFee(for transactionHash: String) -> AnyPublisher<[Fee], Error>
    func pushTransaction(with transactionHash: String, newTransaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error>
}

@available(iOS 13.0, *)
public protocol SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error>
}

public protocol WithdrawalValidator {
    func validate(_ transaction: Transaction) -> WithdrawalWarning?
}

@available(iOS 13.0, *)
public protocol AddressModifier {
    func modify(_ address: String) async throws -> String
}

public struct WithdrawalWarning {
    public let warningMessage: String
    public let reduceMessage: String
    public var ignoreMessage: String? = nil
    public let suggestedReduceAmount: Amount
}

public protocol RentProvider {
    func minimalBalanceForRentExemption() -> AnyPublisher<Amount, Error>
    func rentAmount() -> AnyPublisher<Amount, Error>
}

public protocol ExistentialDepositProvider {
    var existentialDeposit: Amount { get }
}
