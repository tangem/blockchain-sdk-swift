//
//  NearWalletManager.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 04.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class NearWalletManager: BaseManager, WalletManager {
    var networkService: NearNetworkService!
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        
    }
    
    var currentHost: String = ""
    
    var allowsFeeSelection: Bool = false
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        return Just(Void())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        let isTestnet = wallet.blockchain.isTestnet
        return networkService
            .gasPrice()
            .map { gasPrice -> [Amount] in
                return [Amount(with: .near(testnet: isTestnet), value: Decimal(gasPrice))]
            }
            .eraseToAnyPublisher()
    }
}

extension NearWalletManager: ThenProcessable {}
