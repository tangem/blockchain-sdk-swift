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
    public func hash(into hasher: inout Hasher) {
        hasher.combine(contractAddress.lowercased())
        hasher.combine(blockchain)
        hasher.combine(derivationPath)
    }
    
    public static func == (lhs: Token, rhs: Token) -> Bool {
        lhs.contractAddress.lowercased() == rhs.contractAddress.lowercased() &&
        lhs.derivationPath == rhs.derivationPath
    }
    
    public let name: String
    public let symbol: String
    public let contractAddress: String
    public let decimalCount: Int
    public let customIconUrl: String?
    public let blockchain: Blockchain
    public let derivationPath: DerivationPath?
    
    public init(name: String? = nil, symbol: String, contractAddress: String, decimalCount: Int, customIconUrl: String? = nil, blockchain: Blockchain, derivationPath: DerivationPath? = nil) {
        self.name = name ?? symbol
        self.symbol = symbol
        self.contractAddress = contractAddress
        self.decimalCount = decimalCount
        self.customIconUrl = customIconUrl
        self.blockchain = blockchain
        self.derivationPath = derivationPath ?? blockchain.derivationPath
    }
    
    init(_ blockhairToken: BlockchairToken, blockchain: Blockchain) {
        self.name = blockhairToken.name
        self.symbol = blockhairToken.symbol
        self.contractAddress = blockhairToken.address
        self.decimalCount = blockhairToken.decimals
        self.customIconUrl = nil
        self.blockchain = blockchain
        self.derivationPath = blockchain.derivationPath
    }
}

public extension Token {
    var decimalValue: Decimal {
        return pow(Decimal(10), decimalCount)
    }
}
