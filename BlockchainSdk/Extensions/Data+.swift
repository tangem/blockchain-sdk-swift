//
//  Data+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//
//extension Data {
//    func sha3(_ variant: SHA3.Variant) -> Data {
//        return Data(Digest.sha3(bytes, variant: variant))
//    }
//}

import Foundation
import CryptoKit
import TangemSdk

extension Data {
    public func aligned(to length: Int = 32) -> Data {
        let bytesCount = self.count
        
        guard bytesCount < length else {
            return self
        }
        
        let prefix = Data(repeating: 0, count: 32 - bytesCount)
        
        return prefix + self
    }
    
    var doubleSha256: Data {
        sha256().sha256()
    }
    
    var ripemd160: Data {
        RIPEMD160.hash(message: self)
    }
    
    var sha256Ripemd160: Data {
        RIPEMD160.hash(message: sha256())
    }
    
    func validateAsEdKey() throws {
        _ = try Curve25519.Signing.PublicKey(rawRepresentation: self)
    }
    
    func validateAsSecp256k1Key() throws {
        _ = try Secp256k1Key(with: self)
    }
}

public extension Data {
    
    func base64EncodedURLSafe(options: Base64DecodingOptions = []) -> String {
        let string = self.base64EncodedString()
        return string
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        
    }
    
    init?(base64EncodedURLSafe string: String, options: Base64DecodingOptions = []) {
        let string = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        self.init(base64Encoded: string, options: options)
    }
    
}
