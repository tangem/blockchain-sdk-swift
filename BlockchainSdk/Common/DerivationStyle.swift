//
//  DerivationStyle.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 30.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum DerivationStyle {
    case legacy //https://github.com/satoshilabs/slips/blob/master/slip-0044.md
    case new //All evm blockchains have identical derivation. Other blockchains - same as legacy
}
