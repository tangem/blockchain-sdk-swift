//
//  CardanoWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class CardanoWalletManager: BaseManager, WalletManager {
    var transactionBuilder: CardanoTransactionBuilder!
    var networkService: CardanoNetworkProvider!
    var currentHost: String { networkService.host }
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(addresses: wallet.addresses.map { $0.value }, tokens: cardTokens)
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
    
    private func updateWallet(with response: CardanoAddressResponse) {
        let balance = Decimal(response.balance) / wallet.blockchain.decimalValue
        wallet.add(coinValue: balance)
        transactionBuilder.update(outputs: response.unspentOutputs)
        
        for (token, value) in response.tokenBalances {
            let balance = Decimal(value) / token.decimalValue
            wallet.add(tokenValue: balance, for: token)
        }
       
        wallet.removePendingTransaction { hash in
            response.recentTransactionsHashes.contains {
                $0.caseInsensitiveCompare(hash) == .orderedSame
            }
        }

        // If we have pending transaction but we haven't unspentOutputs then clear it
        if response.recentTransactionsHashes.isEmpty, response.unspentOutputs.isEmpty {
            wallet.clearPendingTransaction()
        }
    }
}

extension CardanoWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { false }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        // Use Just to switch on global queue because we have async signing
        Just(())
            .receive(on: DispatchQueue.global())
                .tryMap { [weak self] _ -> Data in
                    guard let self else {
                        throw WalletError.empty
                    }

                    return try self.transactionBuilder.buildForSign(transaction: transaction)
                }
                .flatMap { [weak self] dataForSign -> AnyPublisher<Data, Error> in
                    guard let self else {
                        return .anyFail(error: WalletError.empty)
                    }

                    return signer.sign(hash: dataForSign, walletPublicKey: self.wallet.publicKey)
                }
                .tryMap { [weak self] signature -> Data in
                    guard let self else {
                        throw WalletError.empty
                    }

                    let signatureInfo = SignatureInfo(signature: signature, publicKey: self.wallet.publicKey.blockchainKey)
                    return try self.transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
                }
                .flatMap { [weak self] builtTransaction -> AnyPublisher<String, Error> in
                    guard let self else {
                        return .anyFail(error: WalletError.empty)
                    }

                    return self.networkService.send(transaction: builtTransaction)
                        .mapError { SendTxError(error: $0, tx: builtTransaction.hexString.lowercased()) }
                        .eraseToAnyPublisher()
                }
                .tryMap { [weak self] hash in
                    guard let self = self else {
                        throw WalletError.empty
                    }
                    
                    let mapper = PendingTransactionRecordMapper()
                    let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                    self.wallet.addPendingTransaction(record)
                    return TransactionSendResult(hash: hash)
                }
                .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        do {
            var feeValue = try transactionBuilder.getFee(amount: amount, destination: destination, source: defaultSourceAddress)
            feeValue.round(scale: wallet.blockchain.decimalCount, roundingMode: .up)
            feeValue /= wallet.blockchain.decimalValue
            let feeAmount = Amount(with: wallet.blockchain, value: feeValue)
            let fee = Fee(feeAmount)
            return .justWithError(output: [fee])
        } catch {
            return .anyFail(error: error)
        }
    }
}

extension CardanoWalletManager: ThenProcessable {}

// MARK: - DustRestrictable

extension CardanoWalletManager: DustRestrictable {
    var dustValue: Amount {
        return Amount(with: wallet.blockchain, value: 1)
    }
}

// MARK: - WithdrawalNotificationProvider

extension CardanoWalletManager: WithdrawalNotificationProvider {
    func validateWithdrawalWarning(amount: Amount, fee: Amount) -> WithdrawalWarning? {
        return nil
    }

    func withdrawalSuggestion(amount: Amount, fee: Amount) -> WithdrawalNotification? {
        do {
            let adaValue = try transactionBuilder.buildCardanoSpendingAdaValue(amount: amount, fee: fee)
            let minAmountDecimal = Decimal(adaValue) / wallet.blockchain.decimalValue
            let amount = Amount(with: wallet.blockchain, value: minAmountDecimal)

            return .cardanoWillBeSendAlongToken(amount: amount)

        } catch {
            print("CardanoWalletManager", #function, "catch error: \(error)")
            return nil
        }
    }
}

// MARK: - CardanoTransferRestrictable

extension CardanoWalletManager: CardanoTransferRestrictable {
    func validateCardanoTransfer(amount: Amount, fee: Amount) throws {
        switch amount.type {
        case .coin:
            let hasTokensWithBalance = wallet.amounts.contains { amountType, amount in
                amountType.isToken && amount.value > 0
            }

            guard hasTokensWithBalance else {
                // Skip this checking. Dust checking will be after
                return
            }
            
            try validateCardanoCoinWithdrawal(amount: amount, fee: fee)
        case .token:
            try validateCardanoTokenWithdrawal(amount: amount, fee: fee)
        case .reserve:
            throw BlockchainSdkError.notImplemented
        }
    }

    private func validateCardanoCoinWithdrawal(amount: Amount, fee: Amount) throws {
        assert(!amount.type.isToken, "Only coin validation")

        guard let adaBalance = wallet.amounts[.coin]?.value else {
            throw ValidationError.balanceNotFound
        }

        let minChange = try minChange(amount: amount)
        var change = adaBalance - amount.value

        if amount.type == fee.type {
            change -= fee.value
        }

        if change < minChange.value {
            throw ValidationError.cardanoHasTokens(minimumAmount: minChange)
        }
    }

    private func validateCardanoTokenWithdrawal(amount: Amount, fee: Amount) throws {
        assert(amount.type.isToken, "Only token validation")

        guard var adaBalance = wallet.amounts[.coin]?.value else {
            throw ValidationError.balanceNotFound
        }

        guard let tokenBalance = wallet.amounts[amount.type]?.value else {
            throw ValidationError.balanceNotFound
        }

        // the fee will be spend in any case
        adaBalance -= fee.value
        
        // 1. Check if there is enough ADA to send the token
        let minAdaValue = try transactionBuilder.buildCardanoSpendingAdaValue(amount: amount, fee: fee)
        let minAdaToSendDecimal = Decimal(minAdaValue) / wallet.blockchain.decimalValue

        // Not enough balance to send token
        if minAdaToSendDecimal > adaBalance {
            throw ValidationError.cardanoInsufficientBalanceToSendToken
        }

        // 2. Check if there is enough ADA to get a change with after transaction
        let minChange = try minChange(amount: amount)
        let change = adaBalance - minAdaToSendDecimal

        // If there not enough ada balance to change
        if change > 0, change < minChange.value {
            throw ValidationError.cardanoInsufficientBalanceToSendToken
        }
    }

    private func minChange(amount: Amount) throws -> Amount {
        let minChangeValue = try transactionBuilder.minChange(amount: amount)
        let minChangeDecimal = Decimal(minChangeValue) / wallet.blockchain.decimalValue
        return Amount(with: wallet.blockchain, value: minChangeDecimal)
    }
}
