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
    public let destination: String
    
    public init(spender: String, destination: String) {
        self.spender = spender
        self.destination = destination
    }
    
    public var prefix: String { "0xdd62ed3e" }
    public var data: Data {
        let prefix = Data(hexString: prefix)
        let spenderData = Data(hexString: spender).aligned(to: 32)
        let destinationData = Data(hexString: destination).aligned(to: 32)
        
        return [spenderData, destinationData].reduce(prefix, +)
    }
}
