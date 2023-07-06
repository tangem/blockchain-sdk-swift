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
            } else {
                if response.recentTransactionsHashes.first(where: { $0.lowercased() == hashLowercased }) != nil {
                    mutableTx.status = .confirmed
                }
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
//                    print("dataForSign ->>", dataForSign.hexString)
                    
                    return .justWithError(output: Data()) // signer.sign(hash: dataForSign, walletPublicKey: self.wallet.publicKey)
                }
                .tryMap { [weak self] signature -> Data in
                    guard let self else {
                        throw WalletError.empty
                    }

//                    let signature = Data(hexString:"3bc9667cbcae52b03b4494bc331ff7c98d426998916ba1ee8e4cbdfddb3eca31098737c7d9fa04f6720188441ae58b59f1c04259a00abfffc8393da5333c1a04")
//                    let publicKey = Data(hexString: "d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41ea7f484aa383806735c46fd769c679ee41f8952952036a6e2338ada940b8a91f40b5aaa6103dc10842894a1eeefc5447b9bcb9bcf227d77e57be195d17bc03263d46f19d0fbf75afb0b9a24e31d533f4fd74cee3b56e162568e8defe37123afc4")
//                    let signatureInfo = SignatureInfo(signature: signature, publicKey: publicKey)
                    return  Data() // try self.transactionBuilder.buildForSend(transaction: transaction, signature: signatureInfo)
                }
                .flatMap { [weak self] builtTransaction -> AnyPublisher<String, Error> in
                    guard let self else {
                        return .anyFail(error: WalletError.empty)
                    }
                    
                    let builtTransaction = Data(hex: "83a400828258208316e5007d61fb90652cabb41141972a38b5bc60954d602cf843476aa3f67f6300825820e29392c59c903fefb905730587d22cae8bda30bd8d9aeec3eca082ae77675946000182825839015fcbab3d70db82b3b9da5686d1ff51c83b97e032e52bd45a6ce6fe7908ec32633484b152fa756444e5fc62128210bc1fd7b8253ec5490b281a002dc6c082583901a9426fe0cee6d01d1fe32af650e1e7b5d52c35d8a53218f3d0861531621c2b1ebdf4f11f96da67fdcb0e1d97a7e778566166be55f193c30f1a000f9ec1021a0002b0bf031a0b532b80a20081825820d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41e58406a23ab9267867fbf021c1cb2232bc83d2cdd663d651d22d59b6cddbca5cb106d4db99da50672f69a2309ca8a329a3f9576438afe4538b013de4591a6dfcd4d090281845820d163c8c4f0be7c22cd3a1152abb013c855ea614b92201497a568c5d93ceeb41e58406a23ab9267867fbf021c1cb2232bc83d2cdd663d651d22d59b6cddbca5cb106d4db99da50672f69a2309ca8a329a3f9576438afe4538b013de4591a6dfcd4d095820a7f484aa383806735c46fd769c679ee41f8952952036a6e2338ada940b8a91f441a0f6")
                    // 
//                    print("builtTransaction.hex ->> ", builtTransaction.hex)

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
            fee: .zero(for: .cardano(shelley: true)),
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
