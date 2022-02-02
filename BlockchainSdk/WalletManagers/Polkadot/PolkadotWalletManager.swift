//
//  PolkadotWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 01.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class PolkadotWalletManager: WalletManager {
    private let network: PolkadotNetwork
    var txBuilder: PolkadotTransactionBuilder!
    var networkService: PolkadotNetworkService!
    
    init(network: PolkadotNetwork, wallet: Wallet) {
        self.network = network
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<(), Error>) -> Void) {
        completion(.success(()))
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
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        .emptyFail
    }
    
    private func sign(amount: Amount, destination: String, meta: PolkadotBlockchainMeta, signer: TransactionSigner) -> AnyPublisher<Data, Error> {
        let x = Just(())
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
        
        return x
    }
}

extension PolkadotWalletManager: ThenProcessable { }
