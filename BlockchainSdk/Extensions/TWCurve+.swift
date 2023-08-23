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
    /// Сonstructor that maps the sdk blockchain curve into the TrustWallet Curve
    init(blockchain: Blockchain) throws {
        switch blockchain {
        case .cardano(let extended):
            self = extended ? .ed25519ExtendedCardano : .ed25519
        default:
            switch blockchain.curve {
            case .secp256k1:
                self = .secp256k1
            case .ed25519_slip0010:
                self = .ed25519
            default:
                throw NSError()
            }
        }
        
    }
}
