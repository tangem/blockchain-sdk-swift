//
//  RosettaResponse.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 19/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct RosettaBalanceResponse: Codable {
    let balances: [RosettaAmount]
    let coins: [RosettaCoin]
    
    var address: String?
}

struct RosettaSubmitResponse: Codable {
    let transactionIdentifier: RosettaTransactionIdentifier
}


//@JsonClass(generateAdapter = true)
//data class RosettaBalanceResponse(
//        val balances: List<RosettaAmount>? = null,
//        val coins: List<RosettaCoin>? = null
//)
//
//@JsonClass(generateAdapter = true)
//data class RosettaSubmitResponse(
//        @Json(name = "transaction_identifier")
//        val transactionIdentifier: RosettaTransactionIdentifier? = null
//)
