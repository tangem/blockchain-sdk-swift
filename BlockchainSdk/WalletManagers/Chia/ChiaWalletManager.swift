//
//  ChiaWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import WalletCore

final class ChiaWalletManager: BaseManager, WalletManager {
    
    // MARK: - Properties
    
    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool = false
    
    // MARK: - Private Properties
    
    private let networkService: ChiaNetworkService
    private let txBuilder: ChiaTransactionBuilder
    private let puzzleHash: String
    
    // MARK: - Init
    
    init(wallet: Wallet, networkService: ChiaNetworkService, txBuilder: ChiaTransactionBuilder) throws {
        self.networkService = networkService
        self.txBuilder = txBuilder
        self.puzzleHash = ChiaConstant.getPuzzle(walletPublicKey: wallet.publicKey.blockchainKey).hex
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getUnspents(puzzleHash: puzzleHash)
            .sink(
                receiveCompletion: { [unowned self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        // TODO: - Hander error completion
                        completion(.failure(error))
                    }
                },
                receiveValue: { [unowned self] response in
                    print(response)
                    completion(.success(()))
                }
            )
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] _ -> String in
                guard let self = self else {
                    throw WalletError.failedToBuildTx
                }
                
                let input = try self.txBuilder.buildForSign(
                    amount: transaction.amount,
                    destination: transaction.destinationAddress
                )
                
                throw WalletError.empty
            }
            .flatMap { [weak self] message -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }
                
                return .emptyFail
                
//                return self.networkService.send(message: message)
            }
            .map { [weak self] hash in
                self?.wallet.add(transaction: transaction)
                return TransactionSendResult(hash: hash)
            }
            .eraseToAnyPublisher()
    }

    func build(transaction: TheOpenNetworkSigningInput, with signer: TransactionSigner? = nil) throws -> String {
        throw WalletError.empty
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return .emptyFail
    }
    
}
