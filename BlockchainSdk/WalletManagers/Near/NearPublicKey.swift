//
//  NearPublicKey.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 06.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// For Implicit account supports only ED25519 curve
class NearPublicKey {
    private let publicKey: [UInt8]
    
    init(from data: Data) {
        publicKey = data.bytes
    }
    
    init(from bytes: [UInt8]) {
        publicKey = bytes
    }
    
    func rawPublicKey() -> String {
        return NearBase58.base58Encode(publicKey)
    }
    
    func txPublicKey() -> String {
        return "ed25519:\(rawPublicKey())"
    }
    
    func address() -> String {
        return rawPublicKey().toHexEncodedString()[..<64].lowercased()
    }
}
