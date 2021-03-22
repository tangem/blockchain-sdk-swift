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
    
    var valueDecimal: Decimal? {
        Decimal(value)
    }
}

struct RosettaCurrency: Codable {
    let symbol: String?
    let decimals: Int?
}

struct RosettaCoin: Codable {
    let coinIdentifier: RosettaCoinIdentifier?
    let amount: RosettaAmount?
}

struct RosettaCoinIdentifier: Codable {
    let identifier: String?
}

struct RosettaTransactionIdentifier: Codable {
    let hash: String?
}
//@JsonClass(generateAdapter = true)
//data class RosettaAmount(
//        val value: Long? = null,
//        val currency: RosettaCurrency? = null
//)
//
//@JsonClass(generateAdapter = true)
//data class RosettaCurrency(
//        val symbol: String? = null,
//        val decimals: Int? = null
//)
//
//@JsonClass(generateAdapter = true)
//data class RosettaCoin(
//        @Json(name = "coin_identifier")
//        val coinIdentifier: RosettaCoinIdentifier? = null,
//        val amount: RosettaAmount? = null
//)
//
//@JsonClass(generateAdapter = true)
//data class RosettaCoinIdentifier(
//        val identifier: String? = null
//)
//
//@JsonClass(generateAdapter = true)
//data class RosettaTransactionIdentifier(
//        val hash: String? = null
//)
