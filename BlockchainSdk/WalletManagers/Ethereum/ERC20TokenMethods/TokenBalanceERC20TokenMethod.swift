//
//  TokenBalanceERC20TokenMethod.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 09.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TokenBalanceERC20TokenMethod: SmartContractMethod {
    public let owner: String

    public init(owner: String) {
        self.owner = owner
    }
    
    public var prefix: String { "0x70a08231" }
    public var data: Data {
        let prefix = Data(hexString: prefix)
        let ownerData = Data(hexString: owner).aligned(to: 32)
        return prefix + ownerData
    }
}
