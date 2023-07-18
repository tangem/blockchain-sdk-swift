//
//  ChiaProviderResponse.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum ChiaStatusResponse: String, Decodable {
    case success, error
}

struct ChiaCoinRecordsResponse: Decodable {
    let coinRecords: [ChiaCoinRecord]
}

struct ChiaSendTransactionResponse: Decodable {
    let status: String
}

struct ChiaCoinRecord: Decodable {
    let coin: ChiaCoin
}
