//
//  NexaWalletManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class NexaWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkProvider.host }

    private let transactionBuilder: NexaTransactionBuilder
    private let networkProvider: ElectrumNetworkProvider
    
    private var decimalValue: Decimal {
        Blockchain.nexa.decimalValue
    }
    
    init(
        wallet: Wallet,
        transactionBuilder: NexaTransactionBuilder,
        networkProvider: ElectrumNetworkProvider
    ) {
        self.transactionBuilder = transactionBuilder
        self.networkProvider = networkProvider
        
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkProvider
            .getAddressInfo(address: wallet.address)
            .receive(on: DispatchQueue.global())
            .sink(receiveCompletion: { [weak self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] info in
                self?.updateWallet(info: info)
                completion(.success(()))
            })
    }
}

// MARK: - Private

private extension NexaWalletManager {
    func updateWallet(info: ElectrumAddressInfo) {
        let balanceSatoshi: Decimal = info.outputs.reduce(0) { result, output in
            if output.isConfirmed {
                return result + output.value
            }
            
            return result
        }
        
        transactionBuilder.update(outputs: info.outputs)

        let balance = balanceSatoshi / decimalValue
        wallet.add(coinValue: balance)
        wallet.clearPendingTransaction()
    }
}

// MARK: - TransactionSender

extension NexaWalletManager: TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        fatalError("TODO")
    }
}

// MARK: - TransactionFeeProvider

extension NexaWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { false }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        fatalError("TODO")
    }
}

// MARK: - DustRestrictable

extension NexaWalletManager: DustRestrictable {
    var dustValue: Amount {
        let value = Decimal(546) / wallet.blockchain.decimalValue
        return Amount(with: wallet.blockchain, type: .coin, value: value)
    }
}

// MARK: - MaximumAmountRestrictable

extension NexaWalletManager: MaximumAmountRestrictable {
    func validateMaximumAmount(amount: Amount, fee: Amount) throws {
        let fullAmount = (amount + fee).value
        let amountAvailableToSend = transactionBuilder.availableToSpendAmount(amount: fullAmount)
        
        guard fullAmount < amountAvailableToSend else {
            return
        }
        
        throw ValidationError.maximumUTXO(
            blockchainName: wallet.blockchain.displayName,
            newAmount: .init(with: amount, value: amountAvailableToSend),
            maxUtxo: NexaTransactionBuilder.maxUTXO
        )
    }
}
