//
//  ElectrumAddressInfo.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ElectrumAddressInfo {
    let outputs: [ElectrumUTXO]
}

public struct ElectrumUTXO {
    let position: Int
    let hash: String
    let value: Decimal
    let outpoint: String
    let height: Decimal
    
    var isConfirmed: Bool {
        height > 0
    }
}
