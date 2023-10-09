//
//  AllowanceERC20TokenMethod.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 18.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct AllowanceERC20TokenMethod: SmartContractMethod {
    public let spender: String
    public let owner: String
    
    public init(owner: String, spender: String) {
        self.owner = owner
        self.spender = spender
    }
    
    public var prefix: String { "0xdd62ed3e" }
    public var data: Data {
        let prefix = Data(hexString: prefix)
        let ownerData = Data(hexString: owner).aligned(to: 32)
        let spenderData = Data(hexString: spender).aligned(to: 32)
        
        return [ownerData, spenderData].reduce(prefix, +)
    }
}
