//
//  TronNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class TronNetworkService {
    private let rpcProvider: TronJsonRpcProvider
    
    init(rpcProvider: TronJsonRpcProvider) {
        self.rpcProvider = rpcProvider
    }
    
    func getAccount(for address: String) -> AnyPublisher<TronGetAccountResponse, Error> {
        rpcProvider.getAccount(for: address)
    }
}
