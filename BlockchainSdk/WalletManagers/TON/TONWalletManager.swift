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

final class TONWalletManager: BaseManager, WalletManager {
    
    // MARK: - Properties
    
    var currentHost: String { provider.host }
    var allowsFeeSelection: Bool { false }
    
    // MARK: - Private Properties
    
    private var provider: TONNetworkProvider!
    private lazy var txBuilder = try? TONTransactionBuilder(walletPublicKey: wallet.publicKey.blockchainKey)
    
    // MARK: - Init
    
    init(wallet: Wallet, provider: TONNetworkProvider) {
        self.provider = provider
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = provider.getBalanceWallet(address: wallet.address)
            .sink(receiveCompletion: {[unowned self]  completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.update(by: response, completion)
            })
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard let txForSign = try? txBuilder?.buildForSign(transaction: transaction, signer: signer) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        do {
            return try signer.sign(
                hash: Data(txForSign.hash()),
                walletPublicKey: wallet.publicKey
            )
            .tryMap { [weak self] signature -> TONExternalMessage? in
                guard let self = self else { throw WalletError.failedToBuildTx }
                return try self.txBuilder?.buildForSend(signingMessage: txForSign, seqno: 339)
            }
            .tryMap { externalMessage in
                guard let externalMessage = externalMessage else { throw WalletError.failedToBuildTx }
                print(externalMessage)
                throw WalletError.empty
            }
            .eraseToAnyPublisher()
        } catch {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        provider.getFee(by: "").eraseToAnyPublisher()
    }
    
    // MARK: - Private Implementation
    
    private func update(by response: Decimal, _ completion: @escaping (Result<Void, Error>) -> Void) {
        wallet.add(coinValue: response)
        completion(.success(()))
    }
    
}
