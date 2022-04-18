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
    
    var networkService: TronNetworkService!
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService.getAccount(for: wallet.address)
            .sink {
                switch $0 {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
                print($0)
            } receiveValue: { [unowned self] in
                print($0)
                self.updateWallet($0)
            }
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        .anyFail(error: WalletError.empty)
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        .anyFail(error: WalletError.empty)
    }
    
    private func updateWallet(_ response: TronGetAccountResponse) {
        let blockchain = wallet.blockchain
        wallet.add(amount: Amount(with: blockchain, value: Decimal(response.balance) / blockchain.decimalValue))
    }
}

extension TronWalletManager: ThenProcessable {

}
