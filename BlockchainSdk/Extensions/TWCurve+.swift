//
//  TWCurve+.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

extension Curve {
    
    /// Сonstructor that maps the sdk blockchain type into the TrustWallet public key type
    init(_ curve: EllipticCurve) throws {
        switch curve {
        case .secp256k1:
            self = .secp256k1
        case .ed25519, .ed25519_slip0010:
            self = .ed25519
        default:
            throw NSError()
        }
    }
    
}
