//
//  PolkadotWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 01.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BigInt
import web3swift

class PolkadotWalletManager: WalletManager {
    private let network: PolkadotNetwork
    var txBuilder: PolkadotTransactionBuilder!
    var networkService: PolkadotNetworkService!
    
    init(network: PolkadotNetwork, wallet: Wallet) {
        self.network = network
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<(), Error>) -> Void) {
        // TODO: Get confirmed transactions as well
        cancellable = networkService.getInfo(for: wallet.address)
            .sink {
                switch $0 {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: {
                self.updateInfo($0)
            }
    }
    
    private func updateInfo(_ balance: BigUInt) {
        let blockchain = network.blockchain
        let decimals = blockchain.decimalCount
        guard
            let formatted = Web3.Utils.formatToPrecision(balance, numberDecimals: decimals, formattingDecimals: decimals, decimalSeparator: ".", fallbackToScientific: false),
            let value = Decimal(formatted)
        else {
            return
        }
        
        wallet.add(amount: .init(with: blockchain, value: value))
        
        let currentDate = Date()
        for (index, transaction) in wallet.transactions.enumerated() {
            if let date = transaction.date,
               DateInterval(start: date, end: currentDate).duration > 10
            {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
}

extension PolkadotWalletManager: TransactionSender {
    var allowsFeeSelection: Bool {
        false
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        networkService
            .blockchainMeta(for: transaction.sourceAddress)
            .flatMap { meta in
                self.sign(amount: transaction.amount, destination: transaction.destinationAddress, meta: meta, signer: signer)
            }
            .flatMap { image in
                self.networkService.submitExtrinsic(data: image)
            }
            .map { transactionID in
                var submittedTransaction = transaction
                submittedTransaction.hash = transactionID
                self.wallet.transactions.append(submittedTransaction)
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        networkService.blockchainMeta(for: destination)
            .flatMap { meta in
                self.sign(amount: amount, destination: destination, meta: meta, signer: DummyTransactionSigner())
            }
            .flatMap { image in
                self.networkService.fee(for: image)
            }
            .map { intValue in
                [Amount(with: self.wallet.blockchain, value: Decimal(intValue) / self.wallet.blockchain.decimalValue)]
            }
            .eraseToAnyPublisher()
    }
    
    private func sign(amount: Amount, destination: String, meta: PolkadotBlockchainMeta, signer: TransactionSigner) -> AnyPublisher<Data, Error> {
        Just(())
            .tryMap { _ in
                try self.txBuilder.buildForSign(
                    amount: amount,
                    destination: destination,
                    meta: meta
                )
            }
            .flatMap { preImage in
                signer.sign(
                    hash: preImage,
                    cardId: self.wallet.cardId,
                    walletPublicKey: self.wallet.publicKey
                )
            }
            .tryMap { signature in
                try self.txBuilder.buildForSend(
                    amount: amount,
                    destination: destination,
                    meta: meta,
                    signature: signature
                )
            }
            .eraseToAnyPublisher()
    }
}

extension PolkadotWalletManager: ThenProcessable { }


// MARK: - Dummy transaction signer

fileprivate class DummyTransactionSigner: TransactionSigner {
    private let privateKey = Data(repeating: 0, count: 32)
    private let curve = EllipticCurve.ed25519
    
    func sign(hashes: [Data], cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        Fail(error: WalletError.failedToGetFee).eraseToAnyPublisher()
    }
    
    func sign(hash: Data, cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        Just<Data>(hash)
            .tryMap { hash in
                try hash.sign(privateKey: privateKey, curve: curve)
            }
            .eraseToAnyPublisher()
    }
}
