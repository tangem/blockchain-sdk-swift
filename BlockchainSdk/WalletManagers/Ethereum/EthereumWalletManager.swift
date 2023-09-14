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
    func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        getFee(to: destination, from: wallet.address, value: value, data: data)
    }

    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
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

// MARK: - Private

private extension EthereumWalletManager {
    func getFee(to: String, from: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        networkService.getFee(to: to, from: from, value: value, data: data?.hexString.addHexPrefix())
            .tryMap { [weak self] ethereumFeeResponse in
                guard let self = self else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let decimalValue = self.wallet.blockchain.decimalValue
                let blockchain = self.wallet.blockchain

                let fees = ethereumFeeResponse.gasPrices.map { gasPrice in
                    let gasLimit = ethereumFeeResponse.gasLimit
                    let feeValue = gasLimit * gasPrice

                    // TODO: Fix integer overflow. Think about BigInt
                    // https://tangem.atlassian.net/browse/IOS-4268
                    let fee = Decimal(Int(feeValue)) / decimalValue

                    let amount = Amount(with: blockchain, value: fee)
                    let parameters = EthereumFeeParameters(gasLimit: gasLimit, gasPrice: gasPrice)

                    return Fee(amount, parameters: parameters)
                }

                return fees
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
        
        if txCount == pendingTxCount {
            for index in wallet.transactions.indices {
                wallet.transactions[index].status = .confirmed
            }
        } else if response.pendingTxs.isEmpty {
            if wallet.transactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.transactions.removeAll()
            response.pendingTxs.forEach {
                wallet.addPendingTransaction($0)
            }
        }
    }
}

// MARK: - TransactionFeeProvider

extension EthereumWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { true }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee],Error> {
        switch amount.type {
        case .coin:
            if let hexAmount = amount.encodedForSend {
                return getFee(destination: destination, value: hexAmount)
            }
        case .token(let token):
            if let erc20Data = txBuilder.getData(for: amount, targetAddress: destination) {
                return getFee(destination: token.contractAddress, data: erc20Data)
            }
        case .reserve:
            break
        }

        return Fail(error: BlockchainSdkError.failedToLoadFee).eraseToAnyPublisher()
    }
}

// MARK: - TransactionSender

extension EthereumWalletManager: TransactionSender {
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
