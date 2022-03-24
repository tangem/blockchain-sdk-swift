//
//  TronRequest.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TronGetAccountRequest: Codable {
    let address: String
    let visible: Bool
}
