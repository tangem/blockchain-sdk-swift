//
//  PublicKeyFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct PublicKeyFactory {
    func makeSeedKey(for curve: EllipticCurve) throws -> Data {
        switch curve {
        case .secp256k1:
            return try Secp256k1Utils().generateKeyPair().publicKey
        case .ed25519:
            return ED25
        case .ed25519_slip0010:
            <#code#>
        case .secp256r1:
            <#code#>
        case .bls12381_G2:
            <#code#>
        case .bls12381_G2_AUG:
            <#code#>
        case .bls12381_G2_POP:
            <#code#>
        case .bip0340:
            <#code#>
        }
    }
}
