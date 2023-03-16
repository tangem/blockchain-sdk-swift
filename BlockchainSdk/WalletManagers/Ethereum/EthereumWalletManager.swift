//
//  EthereumWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine
import TangemSdk
import Moya
import web3swift

class EthereumWalletManager: BaseManager, WalletManager, ThenProcessable {
    var txBuilder: EthereumTransactionBuilder!
    var networkService: EthereumNetworkService!
    
    var txCount: Int = -1
    var pendingTxCount: Int = -1
    
    var currentHost: String { networkService.host }
    
    private var findTokensSubscription: AnyCancellable? = nil

    /// This method for implemented protocol `EthereumTransactionProcessor`
    /// It can't be into extension because it will be override in the `OptimismWalletManager`
    func getFee(payload: EthereumDestinationPayload) -> AnyPublisher<FeeDataModel, Error> {
        getFee(to: payload.targetAddress, value: payload.value, data: payload.data)
    }
}

// MARK: - EthereumTransactionSigner

extension EthereumWalletManager: EthereumTransactionSigner {
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        guard let txForSign = txBuilder.buildForSign(transaction: transaction, nonce: txCount) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return signer.sign(hash: txForSign.hash, walletPublicKey: wallet.publicKey)
            .tryMap { [weak self] signature -> String in
                guard let self = self else { throw WalletError.empty }
                
                guard let tx = self.txBuilder.buildForSend(transaction: txForSign.transaction, hash: txForSign.hash, signature: signature) else {
                    throw WalletError.failedToBuildTx
                }
                
                return "0x\(tx.toHexString())"
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - EthereumNetworkProvider

extension EthereumWalletManager: EthereumNetworkProvider {
    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        networkService.getBalance(address)
    }
    
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        networkService.getTokensBalance(address, tokens: tokens)
    }
    
    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        networkService.getTxCount(address)
    }
    
    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        networkService.getPendingTxCount(address)
    }
}

// MARK: - WalletManager

extension EthereumWalletManager {
    func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(receiveCompletion: {[unowned self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
}

// MARK: - Private

extension EthereumWalletManager {
    func getFee(to: String, value: String?, data: Data?) -> AnyPublisher<FeeDataModel, Error> {
        networkService.getFee(to: to, from: wallet.address, value: value, data: data?.hexString.addHexPrefix())
            .tryMap { [weak self] ethereumFeeResponse in
                guard let self = self else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                let feeAmounts = ethereumFeeResponse.fees.map {
                    Amount(with: self.wallet.blockchain, value: $0)
                }
                
                var feeDataModel = try FeeDataModel(fees: feeAmounts)
                feeDataModel.additionalParameters = ethereumFeeResponse.parameters
                
                print("EthereumWalletManager calculated fees: \(feeDataModel)")
                return feeDataModel
            }
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(with response: EthereumInfoResponse) {
        wallet.add(coinValue: response.balance)
        for tokenBalance in response.tokenBalances {
            wallet.add(tokenValue: tokenBalance.value, for: tokenBalance.key)
        }
       
        txCount = response.txCount
        pendingTxCount = response.pendingTxCount
        
        // TODO: This should be removed when integrating transaction history for all blockchains
        // If we can load transaction history for specified blockchain - we can ignore loading pending txs
        if !wallet.blockchain.canLoadTransactionHistory {
            if !response.pendingTxs.isEmpty {
                wallet.transactions.removeAll()
                response.pendingTxs.forEach {
                    wallet.addPendingTransaction($0)
                }
            } else if txCount == pendingTxCount {
                for  index in wallet.transactions.indices {
                    wallet.transactions[index].status = .confirmed
                }
            } else {
                if wallet.transactions.isEmpty {
                    wallet.addDummyPendingTransaction()
                }
            }
        }
    }
    
    func formatDestinationInfo(for destination: String, amount: Amount) throws -> EthereumDestinationPayload {
        switch amount.type {
        case .coin:
            if let hexAmount = amount.encodedForSend {
                return EthereumDestinationPayload(targetAddress: destination, value: hexAmount)
            }
        case .token(let token):
            if let erc20Data = txBuilder.getData(for: amount, targetAddress: destination) {
                return EthereumDestinationPayload(targetAddress: token.contractAddress, data: erc20Data)
            }
        case .reserve:
            break
        }
        
        throw BlockchainSdkError.failedToLoadFee
    }
}

// MARK: - TransactionSender

extension EthereumWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<FeeDataModel,Error> {
        do {
            let payload = try formatDestinationInfo(for: destination, amount: amount)
            return getFee(payload: payload)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        sign(transaction, signer: signer)
            .flatMap {[weak self] tx -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(transaction: tx).tryMap {[weak self] sendResponse in
                    guard let self = self else { throw WalletError.empty }
                    
                    var tx = transaction
                    tx.hash = sendResponse
                    self.wallet.add(transaction: tx)
                    return TransactionSendResult(hash: sendResponse)
                }
                .mapError { SendTxError(error: $0, tx: tx) }
                .eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - EthereumGasLoader

extension EthereumWalletManager: EthereumGasLoader {
    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        networkService.getGasPrice()
    }
    
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        return networkService
            .getGasLimit(to: to, from: from, value: value, data: data)
            .eraseToAnyPublisher()
    }
}

// MARK: - SignatureCountValidator

extension EthereumWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        networkService.getSignatureCount(address: wallet.address)
            .tryMap {
                if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - TokenFinder

extension EthereumWalletManager: TokenFinder {
    func findErc20Tokens(knownTokens: [Token], completion: @escaping (Result<Bool, Error>)-> Void) {
        findTokensSubscription?.cancel()
        findTokensSubscription = networkService
            .findErc20Tokens(address: wallet.address)
            .sink(receiveCompletion: { subscriptionCompletion in
                if case let .failure(error) = subscriptionCompletion {
                    completion(.failure(error))
                    return
                }
            }, receiveValue: {[unowned self] blockchairTokens in
                if blockchairTokens.isEmpty {
                    completion(.success(false))
                    return
                }
                
                var tokensAdded = false
                blockchairTokens.forEach { blockchairToken in
                    let foundToken = Token(blockchairToken, blockchain: self.wallet.blockchain)
                    if !self.cardTokens.contains(foundToken) {
                        let token: Token = knownTokens.first(where: { $0 == foundToken }) ?? foundToken
                        self.cardTokens.append(token)
                        let balanceValue = Decimal(blockchairToken.balance) ?? 0
                        let balanceWeiValue = balanceValue / pow(Decimal(10), blockchairToken.decimals)
                        self.wallet.add(tokenValue: balanceWeiValue, for: token)
                        tokensAdded = true
                    }
                }
                
                completion(.success(tokensAdded))
            })
    }
}

// MARK: - EthereumTransactionProcessor

extension EthereumWalletManager: EthereumTransactionProcessor {
    var initialNonce: Int {
        self.txCount
    }
    
    func buildForSign(_ transaction: Transaction) -> AnyPublisher<CompiledEthereumTransaction, Error> {
        guard let compiled = txBuilder.buildForSign(transaction: transaction, nonce: txCount) else {
            return .anyFail(error: WalletError.failedToBuildTx)
        }

        return .justWithError(output: compiled)
    }
    
    func buildForSend(_ transaction: SignedEthereumTransaction) -> AnyPublisher<String, Error> {
        guard let tx = txBuilder.buildForSend(transaction: transaction.transaction,
                                              hash: transaction.hash,
                                              signature: transaction.signature) else {
            return .anyFail(error: WalletError.failedToBuildTx)
        }
        
        return .justWithError(output: "0x\(tx.toHexString())")
    }
    
    func send(_ transaction: SignedEthereumTransaction) -> AnyPublisher<String, Error> {
        buildForSend(transaction)
            .flatMap {[weak self] serializedTransaction -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService
                    .send(transaction: serializedTransaction)
                    .mapError { SendTxError(error: $0, tx: serializedTransaction) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func getAllowance(from: String, to: String, contractAddress: String) -> AnyPublisher<Decimal, Error> {
        networkService.getAllowance(from: from, to: to, contractAddress: contractAddress)
            .tryMap { response in
                if let allowance = EthereumUtils.parseEthereumDecimal(response, decimalsCount: 0) {
                    return allowance
                }

                throw ETHError.failedToParseAllowance
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - TransactionHistoryLoader

extension EthereumWalletManager: TransactionHistoryLoader {
    func loadTransactionHistory() -> AnyPublisher<[Transaction], Error> {
        return networkService.loadTransactionHistory(address: wallet.address)
            .map { [weak self] transactionRecords in
                guard let self else { return [] }
                
                // Convert to dictionary for faster lookup
                let tokens: [String: Token] = self.cardTokens.reduce(into: [:]) { $0[$1.contractAddress] = $1 }
                let blockchain = self.wallet.blockchain
                
                let transactions: [Transaction] = transactionRecords.compactMap { transactionRecord in
                    
                    let decimalCount: Int
                    let amountType: Amount.AmountType
                    
                    // It is Token if transaction contain contract address
                    if let contractAddress = transactionRecord.tokenContractAddress {
                        // Is this token added to user token list?
                        guard let token = tokens[contractAddress] else {
                            return nil
                        }
                        
                        amountType = .token(value: token)
                        decimalCount = token.decimalCount
                    } else { // This is coin ransaction
                        amountType = .coin
                        decimalCount = blockchain.decimalCount
                    }
                    
                    guard
                        let amountDecimals = transactionRecord.amount(decimalCount: decimalCount),
                        let feeDecimals = transactionRecord.fee(decimalCount: decimalCount)
                    else { return nil }
                    
                    return Transaction(
                        amount: Amount(with: blockchain, type: amountType, value: amountDecimals),
                        fee: Amount(with: blockchain, value: feeDecimals),
                        sourceAddress: transactionRecord.sourceAddress,
                        destinationAddress: transactionRecord.destinationAddress,
                        changeAddress: .unknown,
                        date: transactionRecord.date,
                        status: transactionRecord.status,
                        hash: transactionRecord.hash
                    )
                }
                return transactions
            }
            .handleEvents(receiveOutput: { [weak self] transactions in
                self?.wallet.setTransactionHistoryList(transactions)
            })
            .eraseToAnyPublisher()
    }
}
