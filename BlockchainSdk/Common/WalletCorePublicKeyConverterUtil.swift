//
//  WalletCorePublicKeyConverterUtil.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 19.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import WalletCore

enum WalletCorePublicKeyConverterUtil {
    static func convert(publicKey: Data, publicKeyType: PublicKeyType) -> Data {
        switch publicKeyType {
        case .secp256k1:
            // Note that this is NOT the extended Secp key
            return compressedSecp256k1Key(publicKey)
        default:
            return publicKey
        }
    }
    
    private static func compressedSecp256k1Key(_ publicKey: Data) -> Data {
        guard let compressedPublicKey = try? Secp256k1Key(with: publicKey).compress() else {
            return publicKey
        }
            
        return compressedPublicKey
    }
}
