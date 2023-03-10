//
//  KaspaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkProvider: BitcoinNetworkProvider {
    var host: String {
        url.hostOrUnknown
    }
    
    var supportsTransactionPush: Bool {
        false
    }
    
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        // TODO
        Just(BitcoinResponse(balance: 1, hasUnconfirmed: false, pendingTxRefs: [], unspentOutputs: []))
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
        
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
}
