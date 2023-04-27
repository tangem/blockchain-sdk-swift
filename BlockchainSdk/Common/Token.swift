//
//  Token.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct Token: Hashable, Equatable, Codable {
    public var id: String?
    public let name: String
    public let symbol: String
    public let contractAddress: String
    public let decimalCount: Int
    public let customIconUrl: String?
    public let exchangeable: Bool?
    
    public init(name: String, symbol: String, contractAddress: String, decimalCount: Int, id: String? = nil, customIconUrl: String? = nil, exchangeable: Bool? = nil) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.contractAddress = contractAddress
        self.decimalCount = decimalCount
        self.customIconUrl = customIconUrl
        self.exchangeable = exchangeable
    }
    
    public init(_ sdkToken: WalletData.Token, id: String? = nil) {
        self.id = id
        self.name = sdkToken.name
        self.symbol = sdkToken.symbol
        self.contractAddress = sdkToken.contractAddress
        self.decimalCount = sdkToken.decimals
        self.customIconUrl = nil
        self.exchangeable = nil
    }
    
    init(_ blockhairToken: BlockchairToken, blockchain: Blockchain) {
        self.id = nil
        self.name = blockhairToken.name
        self.symbol = blockhairToken.symbol
        self.contractAddress = blockhairToken.address
        self.decimalCount = blockhairToken.decimals
        self.customIconUrl = nil
        self.exchangeable = nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(contractAddress.lowercased())
    }
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.contractAddress.lowercased() == rhs.contractAddress.lowercased()
    }
}

public extension Token {
    var decimalValue: Decimal {
        return pow(Decimal(10), decimalCount)
    }
}
