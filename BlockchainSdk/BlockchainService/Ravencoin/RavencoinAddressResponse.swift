//
//  RavencoinAddressResponse.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinAddressResponse: Decodable {
    let addrStr: String?
    let balances : [String]
    let tags : [String]
    let frozen : [String]
    let balance : String?
    let totalReceived : String?
    let totalSent : String?
    let unconfirmedBalance : Int?
    let unconfirmedBalanceSat : Int?
    let unconfirmedTxApperances : Int?
    let txApperances : Int?
    let transactions : [String]
}
