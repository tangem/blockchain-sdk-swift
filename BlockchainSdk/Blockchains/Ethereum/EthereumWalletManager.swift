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

class EthereumWalletManager: BaseManager, WalletManager {
    let txBuilder: EthereumTransactionBuilder
    let networkService: EthereumNetworkService

    var currentHost: String { networkService.host }

    init(wallet: Wallet, txBuilder: EthereumTransactionBuilder, networkService: EthereumNetworkService) {
        self.txBuilder = txBuilder
        self.networkService = networkService

        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.updateWallet(with: response)
                completion(.success(()))
            })
    }

    // It can't be into extension because it will be overridden in the `TelosWalletManager`
    var allowsFeeSelection: Bool { true }

    // It can't be into extension because it will be overridden in the `OptimismWalletManager`
    func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        networkService.getFee(
            to: destination,
            from: defaultSourceAddress,
            value: value,
            data: data?.hexString.addHexPrefix()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, ethereumFeeResponse in
            walletManager.proceedFee(response: ethereumFeeResponse)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - EthereumTransactionSigner

extension EthereumWalletManager: EthereumTransactionSigner {
    /// Build and sign transaction
    /// - Parameters:
    /// - Returns: The hex of the raw transaction ready to be sent over the network
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        do {
            let hashToSign = try txBuilder.buildForSign(transaction: transaction)
            return signer
                .sign(hash: hashToSign, walletPublicKey: wallet.publicKey)
                .withWeakCaptureOf(self)
                .tryMap { walletManager, signatureInfo -> String in
                    let tx = try walletManager.txBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)

                    return tx.hexString.lowercased().addHexPrefix()
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
}

// MARK: - EthereumNetworkProvider

extension EthereumWalletManager: EthereumNetworkProvider {
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error> {
        networkService.getAllowance(owner: owner, spender: spender, contractAddress: contractAddress)
            .tryMap { response in
                if let allowance = EthereumUtils.parseEthereumDecimal(response, decimalsCount: 0) {
                    return allowance
                }

                throw ETHError.failedToParseAllowance
            }
            .eraseToAnyPublisher()
    }

    // Balance

    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        networkService.getBalance(address)
    }

    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        networkService.getTokensBalance(address, tokens: tokens)
    }

    // Nonce

    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        networkService.getTxCount(address)
    }

    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        networkService.getPendingTxCount(address)
    }

    // Fee

    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        networkService
            .getGasLimit(to: to, from: from, value: value, data: data)
    }

    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        networkService.getGasPrice()
    }

    func getBaseFee() -> AnyPublisher<BigUInt, Error> {
        networkService.getBaseFee()
    }

    func getPriorityFee() -> AnyPublisher<BigUInt, Error> {
        networkService.getPriorityFee()
    }
}

// MARK: - Private

private extension EthereumWalletManager {
    func proceedFee(response: EthereumFeeResponse) -> [Fee] {
        var feeParameters = [
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                baseFee: response.baseFees.low,
                priorityFee: response.priorityFees.low
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                baseFee: response.baseFees.market,
                priorityFee: response.priorityFees.market
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                baseFee: response.baseFees.fast,
                priorityFee: response.priorityFees.fast
            ),
        ]

        let fees = feeParameters.map { parameters in
            let gasLimit = parameters.gasLimit
            let feeWEI = gasLimit * (parameters.baseFee + parameters.priorityFee)

            // TODO: Fix integer overflow. Think about BigInt
            // https://tangem.atlassian.net/browse/IOS-4268
            // https://tangem.atlassian.net/browse/IOS-5119
            let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))

            let fee = feeValue / wallet.blockchain.decimalValue
            let amount = Amount(with: wallet.blockchain, value: fee)

            return Fee(amount, parameters: parameters)
        }

        return fees
    }

    func updateWallet(with response: EthereumInfoResponse) {
        wallet.add(coinValue: response.balance)
        for tokenBalance in response.tokenBalances {
            wallet.add(tokenValue: tokenBalance.value, for: tokenBalance.key)
        }

        txBuilder.update(nonce: response.txCount)

        if response.txCount == response.pendingTxCount {
            wallet.clearPendingTransaction()
        } else if response.pendingTxs.isEmpty {
            if wallet.pendingTransactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.clearPendingTransaction()
            response.pendingTxs.forEach {
                let mapper = PendingTransactionRecordMapper()
                let transaction = mapper.mapToPendingTransactionRecord($0, blockchain: wallet.blockchain)
                wallet.addPendingTransaction(transaction)
            }
        }
    }
}

// MARK: - TransactionFeeProvider

extension EthereumWalletManager: TransactionFeeProvider {
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee],Error> {
        do {
            switch amount.type {
            case .coin:
                guard let hexAmount = amount.encodedForSend else {
                    throw BlockchainSdkError.failedToLoadFee
                }

                return getFee(destination: destination, value: hexAmount, data: nil)
            case .token(let token):
                let transferData = try buildForTokenTransfer(destination: destination, amount: amount)
                return getFee(destination: token.contractAddress, value: nil, data: transferData)

            case .reserve:
                throw BlockchainSdkError.notImplemented
            }
        } catch {
            return .anyFail(error: error)
        }
    }
}

// MARK: - TransactionSender

extension EthereumWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        sign(transaction, signer: signer)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, rawTransaction in
                walletManager.networkService.send(transaction: rawTransaction)
                    .mapSendError(tx: rawTransaction)
            }
            .withWeakCaptureOf(self)
            .tryMap { walletManager, hash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                walletManager.wallet.addPendingTransaction(record)

                return TransactionSendResult(hash: hash)
            }
            .eraseSendError()
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

// MARK: - EthereumTransactionDataBuilder

extension EthereumWalletManager: EthereumTransactionDataBuilder {
    func buildForApprove(spender: String, amount: Decimal) -> Data {
        txBuilder.buildForApprove(spender: spender, amount: amount)
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        try txBuilder.buildForTokenTransfer(destination: destination, amount: amount)
    }
}
