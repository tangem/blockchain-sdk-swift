//
//  DecimalAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct DecimalAddressService {
    
    // MARK: - Private Properties
    
    private let isTestnet: Bool
    private let bech32 = Bech32(variant: .bech32)
    private let utils = DecimalUtils()
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

// MARK: - AddressProvider protocol conformance

extension DecimalAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        var addressValue = try makeErcAddress(walletPublicKey: publicKey)
        
        switch addressType {
        case .default:
            break
        case .legacy:
            addressValue = try utils.convertErcAddressToDscAddress(addressHex: addressValue)
        }
        
        return .init(value: addressValue, publicKey: publicKey, type: addressType)
    }
    
    private func makeErcAddress(walletPublicKey: Wallet.PublicKey) throws -> String {
        let walletPublicKey = try Secp256k1Key(with: walletPublicKey.blockchainKey).decompress()
        //skip secp256k1 prefix
        let keccak = walletPublicKey[1...].sha3(.keccak256)
        let addressBytes = keccak[12...]
        let address = addressBytes.hexString.addHexPrefix()
        let checksumAddress = toChecksumAddress(address)!
        return checksumAddress
    }
    
    private func toChecksumAddress(_ address: String) -> String? {
        let address = address.lowercased().removeHexPrefix()
        guard let hash = address.data(using: .utf8)?.sha3(.keccak256).hexString.lowercased().removeHexPrefix() else {
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

// MARK: - AddressValidator protocol conformance

extension DecimalAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard let ercAddress = utils.convertDscAddressToErcAddress(addressHex: address) else {
            return false
        }

        guard !ercAddress.isEmpty,
              ercAddress.hasHexPrefix(),
              ercAddress.count == 42
        else {
            return false
        }


        if let checksummed = toChecksumAddress(ercAddress),
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

// MARK: - Constants

extension DecimalAddressService {
    enum Constants {
        static let addressPrefix = "d0"
        static let legacyAddressPrefix = "dx"
        static let erc55AddressPrefix = "0x"
    }
}
