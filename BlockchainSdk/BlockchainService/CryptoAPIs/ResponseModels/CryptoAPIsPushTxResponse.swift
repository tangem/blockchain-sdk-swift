//
//  CryptoAPIsPushTxResponse.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoAPIsPushTxRequest: Codable {
    let signedTransactionHex: String
}

struct CryptoAPIsPushTxResponse: Codable {
    let transactionId: String
}
