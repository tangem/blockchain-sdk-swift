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
            return "Account with the given public key does not exist on the Hedera network and must be created manually."
        case .failedToCreateAccount:
            return "Failed to create a Hedera network account with the given public key"
        case .unsupportedCurve(let curveName):
            return "Hedera supports either ED25519 or ECDSA (secp256k1) curves. Curve '\(curveName)' is not supported"
        }
    }

    case accountDoesNotExist
    case failedToCreateAccount
    case unsupportedCurve(curveName: String)
}
