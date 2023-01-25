//
//  TONStateInit.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TONStateInit {
    public let stateInit: TONCell
    public let address: TONAddress
    public let code: TONCell
    public let data: TONCell
}
