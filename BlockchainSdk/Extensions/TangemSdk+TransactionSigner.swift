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
    public func sign(hashes: [Data], cardId: String, walletPublicKey: Data) -> AnyPublisher<SignResponse, Error> {
        let future = Future<SignResponse, Error> {[unowned self] promise in
            self.sign(hashes: hashes, cardId: cardId, walletPublicKey: walletPublicKey) { signResult in
                switch signResult {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        return AnyPublisher(future)
    }
}
