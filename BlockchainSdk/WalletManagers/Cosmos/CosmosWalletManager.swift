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
    var allowsFeeSelection: Bool { cosmosChain.allowsFeeSelection }
    
    var networkService: CosmosNetworkService!
    var txBuilder: CosmosTransactionBuilder!
    
    private let cosmosChain: CosmosChain
    
    init(cosmosChain: CosmosChain, wallet: Wallet) {
        self.cosmosChain = cosmosChain
        
        super.init(wallet: wallet)
    }
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let transactionHashes = wallet.transactions
            .filter { $0.status == .unconfirmed }
            .compactMap { $0.hash }
        
        cancellable = networkService
            .accountInfo(for: wallet.address, tokens: cardTokens, transactionHashes: transactionHashes)
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
        guard let feeParameters = transaction.fee.parameters as? CosmosFeeParameters else {
            return .anyFail(error: WalletError.failedToBuildTx)
        }
        
        return Just(())
            .receive(on: DispatchQueue.global())
            .setFailureType(to: Error.self)
            .tryMap { [weak self] Void -> Data in
                guard let self else {
                    throw WalletError.empty
                }

                return try self.txBuilder.buildForSign(transaction: transaction)
            }
            .flatMap { [weak self] hash -> AnyPublisher<Data, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }

                return signer.sign(hash: hash, walletPublicKey: self.wallet.publicKey)
            }
            .tryMap { [weak self] signature -> Data in
                guard let self else {
                    throw WalletError.empty
                }

                return try self.txBuilder.buildForSend(transaction: transaction, signature: signature)
            }
            .flatMap { [weak self] transaction -> AnyPublisher<String, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.send(transaction: transaction)
            }
            .handleEvents(receiveOutput: { [weak self] in
                var submittedTransaction = transaction
                submittedTransaction.hash = $0
                self?.wallet.add(transaction: submittedTransaction)
            })
            .map {
                TransactionSendResult(hash: $0)
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return estimateGas(amount: amount, destination: destination)
            .tryMap { [weak self] gas in
                guard let self = self else { throw WalletError.empty }
                
                let blockchain = self.cosmosChain.blockchain
                let gasPrices = self.cosmosChain.gasPrices(for: amount.type)
                
                return Array(repeating: gas, count: gasPrices.count)
                    .enumerated()
                    .map { index, estimatedGas in
                        let gasMultiplier = self.cosmosChain.gasMultiplier
                        let feeMultiplier = self.cosmosChain.feeMultiplier
                        
                        let gas = estimatedGas * gasMultiplier
                        
                        var feeValueInSmallestDenomination = UInt64(Double(gas) * gasPrices[index] * feeMultiplier)
                        if let tax = self.tax(for: amount) {
                            feeValueInSmallestDenomination += tax
                        }
                        
                        let decimalValue = amount.type.token?.decimalValue ?? blockchain.decimalValue
                        var feeValue = (Decimal(feeValueInSmallestDenomination) / decimalValue)
                        if let extraFee = self.cosmosChain.extraFee(for: amount.value) {
                            feeValue += extraFee
                        }
                        
                        feeValue = feeValue.rounded(blockchain: blockchain)
                        
                        let parameters = CosmosFeeParameters(gas: gas)
                        return Fee(Amount(with: blockchain, type: amount.type, value: feeValue), parameters: parameters)
                    }
            }
            .eraseToAnyPublisher()
    }
    
    private func estimateGas(amount: Amount, destination: String) -> AnyPublisher<UInt64, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .tryMap { [weak self] Void -> Data in
                guard let self else { throw WalletError.empty }
                let transaction = Transaction(
                    amount: amount,
                    fee: Fee(.zeroCoin(for: self.wallet.blockchain)),
                    sourceAddress: self.wallet.address,
                    destinationAddress: destination,
                    changeAddress: self.wallet.address
                )

                return try self.txBuilder.buildForSend(
                    transaction: transaction,
                    signature: Data(repeating: 1, count: 64) // Dummy signature
                )
            }
            .tryCatch { _ -> AnyPublisher<Data, Error> in
                .anyFail(error: WalletError.failedToGetFee)
            }
            .flatMap { [weak self] transaction -> AnyPublisher<UInt64, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.estimateGas(for: transaction)
            }
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(accountInfo: CosmosAccountInfo) {
        wallet.add(amount: accountInfo.amount)
        if let accountNumber = accountInfo.accountNumber {
            txBuilder.setAccountNumber(accountNumber)
        }
        txBuilder.setSequenceNumber(accountInfo.sequenceNumber)
        
        for (token, balance) in accountInfo.tokenBalances {
            wallet.add(tokenValue: balance, for: token)
        }
        
        for (index, transaction) in wallet.transactions.enumerated() {
            if let hash = transaction.hash, accountInfo.confirmedTransactionHashes.contains(hash) {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
    
    private func tax(for amount: Amount) -> UInt64? {
        guard case .token(let token) = amount.type,
              let taxPercent = cosmosChain.taxPercentByContractAddress[token.contractAddress]
        else {
            return nil
        }
        
        let amountInSmallestDenomination = amount.value * token.decimalValue
        let taxAmount = amountInSmallestDenomination * taxPercent / 100
        
        return (taxAmount as NSDecimalNumber).uint64Value
    }
}

extension CosmosWalletManager: ThenProcessable { }
