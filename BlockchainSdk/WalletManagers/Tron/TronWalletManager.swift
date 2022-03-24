//
//  TronWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class TronWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        fatalError()
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        .anyFail(error: WalletError.empty)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        .anyFail(error: WalletError.empty)
    }
}

extension TronWalletManager: ThenProcessable {

}
