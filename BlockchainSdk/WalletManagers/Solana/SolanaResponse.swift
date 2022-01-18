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
    let tokens: [SolanaTokenAccountInfoResponse]
}

struct SolanaTokenAccountInfoResponse {
    let balance: Decimal
    let token: Token
}
