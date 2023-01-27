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
        guard let txForSign = try? txBuilder?.buildForSign(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        do {
            return try signer.sign(
                hash: Data(txForSign.hash()),
                walletPublicKey: wallet.publicKey
            )
            .tryMap { [weak self] signature -> TONExternalMessage? in
                let dummySignature = true
                let signature = try dummySignature ? Data([UInt8](repeating: 0, count: 64)) : NaclSign.signDetached(
                    message: Data(txForSign.hash()),
                    secretKey: Data(hex: "3bab423792cc6d5df5efc96eb800af9c83ac9761548e5c1f472e63ac5a406de6995b3e6c86d4126f52a19115ea30d869da0b2e5502a19db1855eeb13081b870b")
                )
                
                
                guard let self = self else { throw WalletError.failedToBuildTx }
                return try self.txBuilder?.buildForSend(
                    signingMessage: txForSign,
                    signature: signature
                )
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
        guard let txForEstimateFee = try? txBuilder?.buildForEstimateFee(amount: amount, destination: destination) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return provider.getFee(by: txForEstimateFee).eraseToAnyPublisher()
    }
    
    // MARK: - Private Implementation
    
    private func update(by response: Decimal, _ completion: @escaping (Result<Void, Error>) -> Void) {
        txBuilder?.seqno = 348
        wallet.add(coinValue: response)
        completion(.success(()))
    }
    
}
