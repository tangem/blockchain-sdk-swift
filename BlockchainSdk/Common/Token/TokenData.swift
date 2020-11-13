//
//  TokenData.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct TokenData {
    public let symbol: String
    public let contractAddress: String
    public let decimal: Int
    
    public init(symbol: String, contractAddress: String, decimal: Int) {
        self.symbol = symbol
        self.contractAddress = contractAddress
        self.decimal = decimal
    }
}
