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
    
    var currentHost: String { service.host }
    var allowsFeeSelection: Bool { false }
    
    // MARK: - Private Properties
    
    private var service: TONNetworkService
    private var txBuilder: TONTransactionBuilder
    
    // MARK: - Init
    
    init(wallet: Wallet, service: TONNetworkService) throws {
        self.service = service
        self.txBuilder = try! .init(wallet: wallet)
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = service
            .getInfoWallet(address: wallet.address)
            .sink(
                receiveCompletion: { [unowned self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        self.wallet.amounts = [:]
                        completion(.failure(error))
                    }
                },
                receiveValue: { [unowned self] result in
                    self.update(by: result, completion)
                }
            )
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        do {
            let txForSignCell = try txBuilder.buildForSign(transaction: transaction)

            return try signer
                .sign(hash: txForSignCell.hashData(), walletPublicKey: wallet.publicKey)
                .tryMap { [weak self] signature -> TONExternalMessage? in
                    guard let self = self else { throw WalletError.failedToBuildTx }
                    return try self.txBuilder.buildForSend(signingMessage: txForSignCell, signature: signature)
                }
                .flatMap { [weak self] externalMessage -> AnyPublisher<Void, Error> in
                    guard let externalMessage = externalMessage else {
                        return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                    }

                    return self?.service
                        .send(message: externalMessage).tryMap {_ in return }
                        .eraseToAnyPublisher() ?? .emptyFail
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        guard let txForEstimateFee = try? txBuilder.buildForEstimateFee(amount: amount, destination: destination) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }

        return service.getFee(message: txForEstimateFee).eraseToAnyPublisher()
    }
    
    // MARK: - Private Implementation
    
    private func update(by info: (Decimal, Int), _ completion: @escaping (Result<Void, Error>) -> Void) {
        wallet.add(coinValue: info.0)
        txBuilder.seqno = info.1
        completion(.success(()))
    }
    
}
                
