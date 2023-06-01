//
//  RosettaData.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 15/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct RosettaNetworkIdentifier: Codable {
    let blockchain: String
    let network: String
    
    static let mainNet = RosettaNetworkIdentifier(blockchain: "cardano", network: "mainnet")
}

struct RosettaAccountIdentifier: Codable {
    let address: String
}

struct RosettaAmount: Codable {
    let value: String?
    let currency: RosettaCurrency?
}

struct RosettaCurrency: Codable {
    let symbol: String?
    let decimals: Int?
}

struct RosettaCoin: Codable {
    let coinIdentifier: RosettaCoinIdentifier?
    let amount: RosettaAmount?
    let metadata: RosettaMetadata?
}

struct RosettaMetadata: Codable {
    let metadata: [String: [RosettaMetadataValue]]?
}

struct RosettaMetadataValue: Codable {
    let policyId: String?
}

struct RosettaCoinIdentifier: Codable {
    let identifier: String?
}

struct RosettaTransactionIdentifier: Codable {
    let hash: String?
}
