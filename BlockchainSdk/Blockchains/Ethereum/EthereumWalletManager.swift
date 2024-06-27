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
    let addressConverter: EthereumAddressConverter
    let allowsFeeSelection: Bool

    var currentHost: String { networkService.host }

    init(
        wallet: Wallet,
        addressConverter: EthereumAddressConverter,
        txBuilder: EthereumTransactionBuilder,
        networkService: EthereumNetworkService,
        allowsFeeSelection: Bool
    ) {
        self.txBuilder = txBuilder
        self.networkService = networkService
        self.addressConverter = addressConverter
        self.allowsFeeSelection = allowsFeeSelection

        super.init(wallet: wallet)
    }

    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        do {
            let address = try addressConverter.convertToETHAddress(wallet.address)
            cancellable = networkService
                .getInfo(address: address, tokens: cardTokens)
                .sink(receiveCompletion: { [weak self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        self?.wallet.clearAmounts()
                        completion(.failure(error))
                    }
                }, receiveValue: { [weak self] response in
                    self?.updateWallet(with: response)
                    completion(.success(()))
                })
        } catch {
            completion(.failure(error))
        }
    }

    // It can't be into extension because it will be overridden in the `OptimismWalletManager`
    func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        do {
            let from = try addressConverter.convertToETHAddress(defaultSourceAddress)
            let destination = try addressConverter.convertToETHAddress(destination)
            if wallet.blockchain.supportsEIP1559 {
                return getEIP1559Fee(from: from, destination: destination, value: value, data: data)
            } else {
                return getLegacyFee(from: from, destination: destination, value: value, data: data)
            }
        } catch {
            return .anyFail(error: error)
        }
    }
}

// MARK: - EthereumTransactionSigner

extension EthereumWalletManager: EthereumTransactionSigner {
    /// Build and sign transaction
    /// - Parameters:
    /// - Returns: The hex of the raw transaction ready to be sent over the network
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        do {
            let transaction = try convertAddresses(in: transaction)
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
        do {
            let owner = try addressConverter.convertToETHAddress(owner)
            let spender = try addressConverter.convertToETHAddress(spender)
            let contractAddress = try addressConverter.convertToETHAddress(contractAddress)
            return networkService.getAllowance(owner: owner, spender: spender, contractAddress: contractAddress)
                .tryMap { response in
                    if let allowance = EthereumUtils.parseEthereumDecimal(response, decimalsCount: 0) {
                        return allowance
                    }

                    throw ETHError.failedToParseAllowance
                }
                .eraseToAnyPublisher()
        }
        catch {
            return .anyFail(error: error)
        }
    }

    // Balance

    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        do {
            let address = try addressConverter.convertToETHAddress(address)
            return networkService.getBalance(address)
        }
        catch {
            return .anyFail(error: error)
        }
    }

    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error> {
        do {
            let address = try addressConverter.convertToETHAddress(address)
            return networkService.getTokensBalance(address, tokens: tokens)
        }
        catch {
            return .anyFail(error: error)
        }
    }

    // Nonce

    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        do {
            let address = try addressConverter.convertToETHAddress(address)
            return networkService.getTxCount(address)
        }
        catch {
            return .anyFail(error: error)
        }
    }

    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        do {
            let address = try addressConverter.convertToETHAddress(address)
            return networkService.getPendingTxCount(address)
        }
        catch {
            return .anyFail(error: error)
        }
    }

    // Fee

    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        do {
            let to = try addressConverter.convertToETHAddress(to)
            let from = try addressConverter.convertToETHAddress(from)
            return networkService
                .getGasLimit(to: to, from: from, value: value, data: data)
        }
        catch {
            return .anyFail(error: error)
        }
    }

    func getGasPrice() -> AnyPublisher<BigUInt, Error> {
        networkService.getGasPrice()
    }

    func getFeeHistory() -> AnyPublisher<EthereumFeeHistory, Error> {
        networkService.getFeeHistory()
    }
}

// MARK: - Private

private extension EthereumWalletManager {
    func getEIP1559Fee(from: String, destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        networkService.getEIP1559Fee(
            to: destination,
            from: from,
            value: value,
            data: data?.hexString.addHexPrefix()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, ethereumFeeResponse in
            walletManager.proceedEIP1559Fee(response: ethereumFeeResponse)
        }
        .eraseToAnyPublisher()
    }

    func proceedEIP1559Fee(response: EthereumEIP1559FeeResponse) -> [Fee] {
        let feeParameters = [
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.low.max,
                priorityFee: response.fees.low.priority
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.market.max,
                priorityFee: response.fees.market.priority
            ),
            EthereumEIP1559FeeParameters(
                gasLimit: response.gasLimit,
                maxFeePerGas: response.fees.fast.max,
                priorityFee: response.fees.fast.priority
            ),
        ]

        let fees = feeParameters.map { parameters in
            let feeValue = parameters.calculateFee(decimalValue: wallet.blockchain.decimalValue)
            let amount = Amount(with: wallet.blockchain, value: feeValue)

            return Fee(amount, parameters: parameters)
        }

        return fees
    }

    func getLegacyFee(from: String, destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        networkService.getLegacyFee(
            to: destination,
            from: from,
            value: value,
            data: data?.hexString.addHexPrefix()
        )
        .withWeakCaptureOf(self)
        .map { walletManager, ethereumFeeResponse in
            walletManager.proceedLegacyFee(response: ethereumFeeResponse)
        }
        .eraseToAnyPublisher()
    }

    func proceedLegacyFee(response: EthereumLegacyFeeResponse) -> [Fee] {
        let feeParameters = [
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.lowGasPrice
            ),
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.marketGasPrice
            ),
            EthereumLegacyFeeParameters(
                gasLimit: response.gasLimit,
                gasPrice: response.fastGasPrice
            ),
        ]

        let fees = feeParameters.map { parameters in
            let feeValue = parameters.calculateFee(decimalValue: wallet.blockchain.decimalValue)
            let amount = Amount(with: wallet.blockchain, value: feeValue)

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

    func convertAddresses(in transaction: Transaction) throws -> Transaction {
        do {
            var tx = transaction
            tx.sourceAddress = try addressConverter.convertToETHAddress(tx.sourceAddress)
            tx.destinationAddress = try addressConverter.convertToETHAddress(tx.destinationAddress)
            tx.changeAddress = try addressConverter.convertToETHAddress(tx.changeAddress)
            tx.contractAddress = try tx.contractAddress.map { try addressConverter.convertToETHAddress($0) }
            return tx
        } catch {
            throw EthereumAddressConverterError.failedToConvertAddress(error: error)
        }
    }
}

// MARK: - TransactionFeeProvider

extension EthereumWalletManager: TransactionFeeProvider {
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee],Error> {
        do {
            let destination = try addressConverter.convertToETHAddress(destination)
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
        do {
            let transaction = try convertAddresses(in: transaction)
            return sign(transaction, signer: signer)
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
        } catch {
            return .anyFail(error: SendTxError(error: error))
        }
    }
}

// MARK: - SignatureCountValidator

extension EthereumWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        do {
            let address = try addressConverter.convertToETHAddress(wallet.address)
            return networkService.getSignatureCount(address: address)
                .tryMap {
                    if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: SendTxError(error: error))
        }
    }
}

// MARK: - EthereumTransactionDataBuilder

extension EthereumWalletManager: EthereumTransactionDataBuilder {
    func buildForApprove(spender: String, amount: Decimal) throws -> Data {
        let spender = try addressConverter.convertToETHAddress(spender)
        return txBuilder.buildForApprove(spender: spender, amount: amount)
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        let destination = try addressConverter.convertToETHAddress(destination)
        return try txBuilder.buildForTokenTransfer(destination: destination, amount: amount)
    }
}
