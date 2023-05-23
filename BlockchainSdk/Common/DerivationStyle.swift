//
//  DerivationStyle.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 30.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum DerivationStyle {
    @available(*, deprecated, message: "Will be removed after refactoring")
    case legacy
    
    @available(*, deprecated, message: "Will be removed after refactoring")
    case new
    
    /// All have derivation according to BIP44 `coinType`
    /// https://github.com/satoshilabs/slips/blob/master/slip-0044.md
    case v1
    
    /// `EVM-like` have identical derivation with `ethereumCoinType == 60`
    /// Other blockchains - according to BIP44 `coinType`
    case v2
    
    /// `EVM-like` blockchains have identical derivation with `ethereumCoinType == 60`
    /// `Bitcoin-like` blockchains have different derivation related to `BIP`. For example `Legacy` and `SegWit`
    case v3
}
