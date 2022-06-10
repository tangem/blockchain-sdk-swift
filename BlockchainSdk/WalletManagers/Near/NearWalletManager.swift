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
        networkService
            .accountInfo(publicKey: wallet.publicKey.blockchainKey)
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    completion(.failure(error))
                }
            } receiveValue: { [weak self] response in
                guard let self = self else {
                    return
                }
                self.updateWallet(info: response)
                completion(.success(Void()))
            }.store(in: &bag)

    }
    
    private func updateWallet(info: NearAccountInfoResponse) {
        self.wallet.add(coinValue: NearAccountInfoResponse.convertBalance(from: info.result.amount))
        
        for cardToken in cardTokens {
//            let mintAddress = cardToken.contractAddress
//            let balance = info.tokensByMint[mintAddress]?.balance ?? Decimal(0)
//            self.wallet.add(tokenValue: balance, for: cardToken)
        }
        
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
