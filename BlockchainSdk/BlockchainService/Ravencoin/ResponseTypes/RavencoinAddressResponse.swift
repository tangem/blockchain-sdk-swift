//
//  RavencoinAddressResponse.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinAddressResponse: Decodable {
    let addrStr: String
//    let balances: [Balance]
    
    let balance: Decimal
    let balanceSat: Decimal
    
//    let tags: [String]
//    let frozen: [String]
    
    let totalReceived: Decimal
    let totalReceivedSat: Decimal
    
    let totalSent: Decimal
    let totalSentSat: Decimal
    
    let unconfirmedBalance: Decimal
    let unconfirmedBalanceSat: Decimal
    let unconfirmedTxApperances: Decimal
    let txApperances: Decimal
    let transactions: [String]?
}

extension RavencoinAddressResponse {
    struct Balance : Decodable {
        let RNV: RVN
    }
    
    struct RVN: Decodable {
        let totalReceived: Decimal
        let totalSpent: Decimal
        let balance: Decimal
    }
}
