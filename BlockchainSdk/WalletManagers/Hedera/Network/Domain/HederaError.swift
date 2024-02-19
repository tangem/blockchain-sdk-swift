//
//  HederaError.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 09.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum HederaError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .accountDoesNotExist:
            return "Account with a given public key does not exist on the Hedera network and must be created manually."
        case .unsupportedCurve(let curveName):
            return "Hedera supports either ED25519 or ECDSA (secp256k1) curves. Curve '\(curveName)' is not supported"
        }
    }

    case accountDoesNotExist
    case unsupportedCurve(curveName: String)
}
