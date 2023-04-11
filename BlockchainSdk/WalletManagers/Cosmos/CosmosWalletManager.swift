//
//  CosmosWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import WalletCore

class CosmosWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool { false }
    
    var networkService: CosmosNetworkService!
    var txBuilder: CosmosTransactionBuilder!
    
    private let cosmosChain: CosmosChain
    
    init(cosmosChain: CosmosChain, wallet: Wallet) {
        self.cosmosChain = cosmosChain
        
        super.init(wallet: wallet)
    }
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .accountInfo(for: wallet.address)
            .sink { result in
                switch result {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: {
                self.updateWallet(accountInfo: $0)
            }
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        .anyFail(error: WalletError.empty)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        estimateGas(amount: amount, destination: destination, initialGasApproximation: nil)
            .flatMap { [weak self] initialGasEstimation -> AnyPublisher<UInt64, Error> in
                guard let self else { return .anyFail(error: WalletError.empty) }
                
                return self.estimateGas(amount: amount, destination: destination, initialGasApproximation: initialGasEstimation)
            }
            .tryMap { [weak self] gas in
                guard let self = self else { throw WalletError.empty }
                
                let blockchain = self.cosmosChain.blockchain
                
                return Array(repeating: gas, count: self.cosmosChain.gasPrices.count)
                    .enumerated()
                    .map { index, gas in
                        let value = Decimal(Double(gas) * self.cosmosChain.gasPrices[index]) / blockchain.decimalValue
                        return Fee(Amount(with: blockchain, value: value))
                    }
            }
            .eraseToAnyPublisher()
    }
    
    private func estimateGas(amount: Amount, destination: String, initialGasApproximation: UInt64?) -> AnyPublisher<UInt64, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .tryMap { [weak self] Void -> Data in
                guard let self else { throw WalletError.empty }
                
                let feeAmount: Decimal?
                if let initialGasApproximation {
                    let regularGasPrice = cosmosChain.gasPrices[1]
                    feeAmount = Decimal(Double(initialGasApproximation) * regularGasPrice) / self.cosmosChain.blockchain.decimalValue
                } else {
                    feeAmount = nil
                }
                
                let input = try txBuilder.buildForSign(
                    amount: amount,
                    source: self.wallet.address,
                    destination: destination,
                    feeAmount: feeAmount,
                    gas: initialGasApproximation
                )

                guard let privateKey = PrivateKey(data: Data(repeating: 1, count: 32)) else {
                guard let outputData = output.serialized.data(using: .utf8) else {
                    throw WalletError.failedToGetFee
                }
                
                let dummySigner = PrivateKeySigner(privateKey: privateKey, coin: .cosmos)
                return try txBuilder.buildForSend(input: input, signer: dummySigner)
            }
            .tryCatch { _ -> AnyPublisher<Data, Error> in
                .anyFail(error: WalletError.failedToGetFee)
            }
            .flatMap { [weak self] tx -> AnyPublisher<UInt64, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.estimateGas(for: tx)
            }
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(accountInfo: CosmosAccountInfo) {
        wallet.add(amount: accountInfo.amount)
        txBuilder.setAccountNumber(accountInfo.accountNumber)
        txBuilder.setSequenceNumber(accountInfo.sequenceNumber)
        
        // Transactions are confirmed instantaneuously
        for (index, _) in wallet.transactions.enumerated() {
            wallet.transactions[index].status = .confirmed
        }
    }
}

extension CosmosWalletManager: ThenProcessable { }
