//
//  CardManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

@available(iOS 13.0, *)
extension TangemSdk: TransactionSigner {
    public func sign(hashes: [Data], cardId: String, walletPublicKey: Data, hdPath: DerivationPath?) -> AnyPublisher<[Data], Error> {
        let future = Future<[Data], Error> {[weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }
            
            self.sign(hashes: hashes, walletPublicKey: walletPublicKey, cardId: cardId, hdPath: hdPath) { signResult in
                switch signResult {
                case .success(let response):
                    promise(.success(response.signatures))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }

    public func sign(hash: Data, cardId: String, walletPublicKey: Data, hdPath: DerivationPath?) -> AnyPublisher<Data, Error> {
        let future = Future<Data, Error> {[weak self] promise in
            guard let self = self else {
                promise(.failure(WalletError.empty))
                return
            }
            
            self.sign(hash: hash, walletPublicKey: walletPublicKey, cardId: cardId, hdPath: hdPath) { signResult in
                switch signResult {
                case .success(let response):
                    promise(.success(response.signature))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }
}
