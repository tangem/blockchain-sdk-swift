//
//  Token.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Token {
    public let currencySymbol: String
    public let contractAddress: String
    public let decimalCount: Int
    public let displayName: String
}
