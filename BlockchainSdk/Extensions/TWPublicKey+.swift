//
//  TWPublicKey+.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 22.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import WalletCore

extension PublicKey {
    convenience init?(tangemPublicKey: Data, publicKeyType: PublicKeyType) {
        let publicKey: Data
        switch publicKeyType {
        case .secp256k1:
            // Note that this is NOT the extended Secp key
            publicKey = Self.compressedSecp256k1Key(tangemPublicKey)
        default:
            publicKey = tangemPublicKey
        }

        self.init(data: publicKey, type: publicKeyType)
    }
    
    private static func compressedSecp256k1Key(_ publicKey: Data) -> Data {
        guard let compressedPublicKey = try? Secp256k1Key(with: publicKey).compress() else {
            return publicKey
        }
        
        return compressedPublicKey
    }
}
