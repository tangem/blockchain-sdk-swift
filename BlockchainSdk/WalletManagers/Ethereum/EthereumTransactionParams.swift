//
//  EthereumTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/04/21.
//

import Foundation
import BigInt

public struct EthereumTransactionParams: TransactionParams {
    public let gasLimit: BigUInt
    public let gasPrice: BigUInt
    public let data: Data?
    public let nonce: Int?
    
    public init(gasLimit: BigUInt, gasPrice: BigUInt, data: Data? = nil, nonce: Int? = nil) {
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.data = data
        self.nonce = nonce
    }
}
