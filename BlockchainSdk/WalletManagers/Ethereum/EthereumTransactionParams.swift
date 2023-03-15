//
//  EthereumTransactionParams.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/04/21.
//

import Foundation
import BigInt

public struct EthereumTransactionParams: TransactionParams {
    public let data: Data
    public let nonce: Int
    public let gasLimit: BigUInt
    public let gasPrice: BigUInt
    
    public init(data: Data, nonce: Int, gasLimit: Int, gasPrice: Int) {
        self.data = data
        self.nonce = nonce
        self.gasLimit = BigUInt(gasLimit)
        self.gasPrice = BigUInt(gasPrice)
    }
}
