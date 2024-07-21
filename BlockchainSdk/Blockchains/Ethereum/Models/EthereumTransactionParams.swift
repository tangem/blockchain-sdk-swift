//
//  EthereumTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/04/21.
//

import Foundation
import BigInt

public struct EthereumTransactionParams: TransactionParams {
    public let data: Data?
    
    public init(data: Data? = nil) {
        self.data = data
    }
}
