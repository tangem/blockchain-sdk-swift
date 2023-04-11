//
//  CosmosWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CosmosWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkService.host }
    var allowsFeeSelection: Bool { false }
    
    var networkService: CosmosNetworkService!
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        .anyFail(error: WalletError.empty)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        .anyFail(error: WalletError.empty)
    }
}
