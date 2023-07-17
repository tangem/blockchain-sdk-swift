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
    
    func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(addresses: wallet.addresses.map { $0.value }, tokens: cardTokens)
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
    
    private func updateWallet(with response: CardanoAddressResponse) {
        wallet.add(coinValue: response.balance)
        transactionBuilder.update(outputs: response.unspentOutputs)
        
        for (key, value) in response.tokenBalances {
            wallet.add(tokenValue: value, for: key)
        }

        wallet.transactions = wallet.transactions.map {
            var mutableTx = $0
            let hashLowercased = mutableTx.hash?.lowercased()
            if response.recentTransactionsHashes.isEmpty {
                if response.unspentOutputs.isEmpty ||
                    response.unspentOutputs.first(where: { $0.transactionHash.lowercased() == hashLowercased }) != nil {
                    mutableTx.status = .confirmed
                }
            } else if response.recentTransactionsHashes.first(where: { $0.lowercased() == hashLowercased }) != nil {
                mutableTx.status = .confirmed
            }
            return mutableTx
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
                    print("dataForSign ->>", dataForSign.hex)
                    
                    return signer.sign(hash: dataForSign, walletPublicKey: self.wallet.publicKey)
                }
                .tryMap { [weak self] signature -> Data in
                    guard let self else {
                        throw WalletError.empty
                    }

                    let signatureInfo = SignatureInfo(signature: signature, publicKey: wallet.publicKey.blockchainKey)
                    return try self.transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
                }
                .flatMap { [weak self] builtTransaction -> AnyPublisher<String, Error> in
                    guard let self else {
                        return .anyFail(error: WalletError.empty)
                    }

                    print("builtTransaction.hex ->> ", builtTransaction.hex)

                    return self.networkService.send(transaction: builtTransaction)
                        .mapError { SendTxError(error: $0, tx: builtTransaction.hex) }
                        .eraseToAnyPublisher()
                }
                .tryMap { [weak self] txHash in
                    guard let self = self else {
                        throw WalletError.empty
                    }

                    var sendedTx = transaction
                    sendedTx.hash = txHash
                    self.wallet.add(transaction: sendedTx)

                    return TransactionSendResult(hash: txHash)
                }
                .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let dummy = Transaction(
            amount: amount,
            fee: Fee(.zeroCoin(for: .cardano)),
            sourceAddress: defaultSourceAddress,
            destinationAddress: destination,
            changeAddress: defaultChangeAddress
        )

        return Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] _ -> [Fee] in
                guard let self else {
                    throw WalletError.empty
                }

                var feeValue = try self.transactionBuilder.estimatedFee(transaction: dummy)
                feeValue.round(scale: self.wallet.blockchain.decimalCount, roundingMode: .up)
                feeValue /= self.wallet.blockchain.decimalValue
                let feeAmount = Amount(with: self.wallet.blockchain, value: feeValue)
                let fee = Fee(feeAmount)
                return [fee]
            }
            .eraseToAnyPublisher()
    }
}

extension CardanoWalletManager: ThenProcessable {}

extension CardanoWalletManager: DustRestrictable {
    var dustValue: Amount {
        return Amount(with: wallet.blockchain, value: 1.0)
    }
}
