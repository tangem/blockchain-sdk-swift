//
//  ElectrumAddressInfo.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ElectrumAddressInfo {
    let balance: Decimal
    let outputs: [ElectrumUTXO]
}
