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
        .emptyFail        
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        .emptyFail
    }
}

extension PolkadotWalletManager: ThenProcessable { }
