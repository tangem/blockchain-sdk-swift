//
//  ApproveERC20TokenMethod.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct ApproveERC20TokenMethod: SmartContractMethod {
    public let spender: String
    public let amount: BigUInt

    public init(spender: String, amount: BigUInt) {
        self.spender = spender
        self.amount = amount
    }
    
    public var prefix: String { "0x095ea7b3" }
    public var data: Data {
        let prefix = Data(hexString: prefix)
        let addressData = Data(hexString: spender).aligned(to: 32)
        let amountData = amount.serialize().aligned(to: 32)
        return [addressData, amountData].reduce(prefix, +)
    }
}
