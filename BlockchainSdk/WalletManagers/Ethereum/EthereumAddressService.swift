//
//  EthereumAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct EthereumAddressService {
    func toChecksumAddress(_ address: String) -> String? {
        let address = address.lowercased().remove("0x")
        guard let hash = address.data(using: .utf8)?.sha3(.keccak256).toHexString() else {
            return nil
        }
        
        var ret = "0x"
        let hashChars = Array(hash)
        let addressChars = Array(address)
        for i in 0..<addressChars.count {
            guard let intValue = Int(String(hashChars[i]), radix: 16) else {
                return nil
            }
            
            if intValue >= 8 {
                ret.append(addressChars[i].uppercased())
            } else {
                ret.append(addressChars[i])
            }
        }
        return ret
    }
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension EthereumAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        let walletPublicKey = try Secp256k1Key(with: publicKey.blockchainKey).decompress()
        //skip secp256k1 prefix
        let keccak = walletPublicKey[1...].sha3(.keccak256)
        let addressBytes = keccak[12...]
        let hexAddressBytes = addressBytes.toHexString()
        let address = "0x" + hexAddressBytes
        let checksumAddress = toChecksumAddress(address)!
        return PlainAddress(value: checksumAddress, publicKey: publicKey, type: addressType) // "0x4BeA6238E0b0f1Fc40e2231B3093511C41F08585"
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension EthereumAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty,
              address.lowercased().starts(with: "0x"),
              address.count == 42
        else {
            return false
        }


        if let checksummed = toChecksumAddress(address),
           checksummed == address {
            return true
        } else {
            let cleanHex = address.stripHexPrefix()
            if cleanHex.lowercased() != cleanHex && cleanHex.uppercased() != cleanHex {
                return false
            }
        }

        return true
    }
}
