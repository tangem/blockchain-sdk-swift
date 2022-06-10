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
    var bag = Set<AnyCancellable>()
    
    var currentHost: String = ""
    var allowsFeeSelection: Bool = false
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let accountInfo = networkService.accountInfo(publicKey: wallet.publicKey.blockchainKey)
        let accountHistory = networkService.accountHistory(publicKey: wallet.publicKey.blockchainKey)
        Publishers.Zip(accountInfo, accountHistory)
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            } receiveValue: { [weak self] info, history in
                guard let self = self else {
                    return
                }
                self.updateWallet(info: info, history: history)
                completion(.success(Void()))
            }.store(in: &bag)

    }
    
    private func updateWallet(info: NearAccountInfoResponse, history: NearAccountHistoryResponse) {
        self.wallet.add(coinValue: NearAccountInfoResponse.convertBalance(from: info.result.amount, countDecimals: wallet.blockchain.decimalCount))
        
//        for (index, transaction) in wallet.transactions.enumerated() {
//            if let hash = transaction.hash, info.confirmedTransactionIDs.contains(hash) {
//                wallet.transactions[index].status = .confirmed
//            }
//        }
    }
    
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
