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
        self.puzzleHash = try ChiaPuzzle.getPuzzleHash(address: wallet.address).hex
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getUnspents(puzzleHash: puzzleHash)
            .sink(
                receiveCompletion: { completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        completion(.failure(error))
                    }
                },
                receiveValue: { [unowned self] response in
                    self.update(with: response, completion: completion)
                }
            )
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        do {
            let hashesForSign = try self.txBuilder.buildForSign(transaction: transaction)
            
            return signer.sign(
                hashes: hashesForSign,
                walletPublicKey: self.wallet.publicKey
            )
            .tryMap { [weak self] signatures -> ChiaSpendBundle in
                guard let self = self else { throw WalletError.empty }
                return try self.txBuilder.buildToSend(signatures: signatures)
            }
            .flatMap { [weak self] spendBundle -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }
                
                return self.networkService.send(spendBundle)
            }
            .map { [weak self] hash in
                self?.wallet.add(transaction: transaction)
                return TransactionSendResult(hash: hash)
            }
            .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        Just(())
            .receive(on: DispatchQueue.global())
            .map { [weak self] hash in
                return [.init(.zeroCoin(for: .chia(testnet: true)))]
            }
            .mapError({ res in
                return WalletError.empty
            })
            .eraseToAnyPublisher()
    }
    
}

// MARK: - Private Implementation

private extension ChiaWalletManager {
    private func update(with coins: [ChiaCoin], completion: @escaping (Result<Void, Error>) -> Void) {
        let decimalBalance = coins.map { Decimal($0.amount) }.reduce(0, +)
        
        if decimalBalance != wallet.amounts[.coin]?.value {
            wallet.transactions = []
        }
        
        let coinBalance = decimalBalance / wallet.blockchain.decimalValue
        
        wallet.add(coinValue: coinBalance)
        txBuilder.unspentCoins = coins
        
        completion(.success(()))
    }
}
