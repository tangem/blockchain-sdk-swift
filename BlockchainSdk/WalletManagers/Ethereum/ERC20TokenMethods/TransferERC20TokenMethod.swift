//
//  TransferERC20SmartContractMethod.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct TransferERC20TokenMethod: SmartContractMethod {
    public let destination: String
    public let amount: BigUInt
    
    public init(destination: String, amount: BigUInt) {
        self.amount = amount
        self.destination = destination
    }
    
    public var prefix: String { "0xa9059cbb" }
    public var data: Data {        
        let prefix = Data(hexString: prefix)
        let addressData = Data(hexString: destination).aligned(to: 32)
        let amountData = amount.serialize().aligned(to: 32)
        return [addressData, amountData].reduce(prefix, +)
    }
}
