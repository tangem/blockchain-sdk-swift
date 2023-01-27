//
//  TONWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TweetNacl

final class TONWalletManager: BaseManager, WalletManager {
    
    // MARK: - Properties
    
    var currentHost: String { provider.host }
    var allowsFeeSelection: Bool { false }
    
    // MARK: - Private Properties
    
    private var provider: TONNetworkProvider!
    private lazy var txBuilder = try? TONTransactionBuilder(wallet: wallet)
    
    // MARK: - Init
    
    init(wallet: Wallet, provider: TONNetworkProvider) {
        self.provider = provider
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = provider.getBalanceWallet(address: wallet.address)
            .sink(
                receiveCompletion: { [unowned self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        self.wallet.amounts = [:]
                        completion(.failure(error))
                    }
                },
                receiveValue: { [unowned self] response in
                    self.update(by: response, completion)
                }
            )
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard let txForSign = try? txBuilder?.buildForDeploy() else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
//        guard let txForDeploy = try? txBuilder?.buildForDeploy() else {
//            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
//        }
        
        do {
            return try signer.sign(
                hash: Data(txForSign.hash()),
                walletPublicKey: wallet.publicKey
            )
            .tryMap { [weak self] signature -> TONExternalMessage? in
                let signature = try NaclSign.signDetached(
                    message: Data(txForSign.hash()),
                    secretKey: Data(
                        hex: ""
                    )
                )
                
                guard let self = self else { throw WalletError.failedToBuildTx }
                return try self.txBuilder?
                    .buildForSignDeploy(
                        signingMessage: txForSign,
                        signature: signature
                    )
            }
            .flatMap { [weak self] externalMessage -> AnyPublisher<Void, Error> in
                guard let externalMessage = externalMessage else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }
                
                return self?.provider.send(message: externalMessage).tryMap { [weak self] _ in
                    return
                }.eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
        } catch {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        guard let txForEstimateFee = try? txBuilder?.buildForEstimateFee(amount: amount, destination: destination) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return provider.getFee(by: txForEstimateFee).eraseToAnyPublisher()
    }
    
    // MARK: - Private Implementation
    
    private func update(by response: Decimal, _ completion: @escaping (Result<Void, Error>) -> Void) {
        txBuilder?.seqno = 85143
        wallet.add(coinValue: response)
        completion(.success(()))
    }
    
}
