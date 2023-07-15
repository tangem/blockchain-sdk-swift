//
//  ChiaProviderResponse.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaCoinRecordsResponse: Decodable {
    let coinRecords: [ChiaCoinRecordResponse]
}

struct ChiaSendTransactionResponse: Decodable {
    let status: String
}

struct ChiaCoinRecordResponse: Decodable {
    let coin: String
}
