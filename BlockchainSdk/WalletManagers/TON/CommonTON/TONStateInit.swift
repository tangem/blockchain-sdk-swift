//
//  TONStateInit.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TONStateInit {
    let stateInit: TONCell
    let address: TONAddress
    let code: TONCell
    let data: TONCell
}
