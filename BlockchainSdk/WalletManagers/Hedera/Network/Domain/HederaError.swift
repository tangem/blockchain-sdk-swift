//
//  HederaError.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 09.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum HederaError: Error {
    /// Account with a given public key does not exist on the Hedera network and must be created manually.
    case accountDoesNotExist
    /// Hedera supports either ED25519 or ECDSA (secp256k1) curves.
    case unsupportedCurve(curveName: String)
}
