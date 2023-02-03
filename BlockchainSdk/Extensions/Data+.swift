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

extension Data {
    
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

extension Data {
    
    init?(optional bytes: Array<UInt8>?) {
        guard bytes == nil else {
            return nil
        }
        
        self = Data(bytes ?? [])
    }
    
}

//polynomial 0x1021
func crc16(data: [UInt8]) -> UInt16 {
    // Calculate checksum for existing bytes
    var crc: UInt16 = 0x0000;
    let polynomial: UInt16 = 0x1021;
    
    for byte in data {
        for bitidx in 0..<8 {
            let bit = ((byte >> (7 - bitidx) & 1) == 1)
            let c15 = ((crc >> 15 & 1) == 1)
            crc <<= 1
            if c15 ^ bit {
                crc ^= polynomial;
            }
        }
    }
    
    return crc & 0xffff;
}
