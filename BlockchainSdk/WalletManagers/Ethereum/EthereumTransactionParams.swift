//
//  EthereumTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/04/21.
//

import Foundation
import web3swift
import BigInt

public struct EthereumTransactionParams: TransactionParams {
    public let data: Data
    public let gasLimit: BigUInt?
    
    public init(data: Data, gasLimit: Int? = nil) {
        self.data = data
        self.gasLimit = gasLimit == nil ? nil : BigUInt(gasLimit!)
    }
}
