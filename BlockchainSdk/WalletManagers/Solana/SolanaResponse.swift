//
//  SolanaResponse.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 18.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SolanaAccountInfoResponse {
    let balance: Decimal
    let tokensByMint: [String: SolanaTokenAccountInfoResponse]
}

struct SolanaTokenAccountInfoResponse {
    let address: String
    let mint: String
    let balance: Decimal
}
