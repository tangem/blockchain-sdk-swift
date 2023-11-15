//
//  DecimalAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import HDWalletKit
import TangemSdk

final class DecimalAddressService {
    
    // MARK: - Private Properties
    
    private let isTestnet: Bool
    private let bech32 = Bech32()
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

// MARK: - AddressProvider protocol conformance

extension DecimalAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        var valueAddress = try makeErcAddress(walletPublicKey: publicKey)
        
        switch addressType {
        case .default:
            break
        case .legacy:
            valueAddress = try convertErcAddressToDscAddress(addressHex: valueAddress)
        }
        
        return .init(value: valueAddress, publicKey: publicKey, type: addressType)
    }
    
    private func makeErcAddress(walletPublicKey: Wallet.PublicKey) throws -> String {
        let walletPublicKeyData = try Secp256k1Key(with: walletPublicKey.blockchainKey).decompress().bytes[1...64]
        let ercAddress = EIP55.encode(Data(walletPublicKeyData))
        return ercAddress
    }
}

// MARK: - AddressValidator protocol conformance

extension DecimalAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        return false
    }
}

// MARK: - Convertation

extension DecimalAddressService {
    
    func convertDscAddressToErcAddress(addressHex: String) -> String? {
        if addressHex.starts(with: Constants.erc55AddressPrefix) {
            return addressHex
        }

        guard let decodeValue = try? bech32.decode(addressHex) else {
            return nil
        }

        let checksumBytes = try? Data(bech32.convertBits(data: decodeValue.checksum.bytes, fromBits: 5, toBits: 8, pad: false))

        return checksumBytes?.toHexString()
    }

    func convertErcAddressToDscAddress(addressHex: String) throws -> String {
        if addressHex.starts(with:Constants.addressPrefix) || addressHex.starts(with: Constants.legacyAddressPrefix) {
            return addressHex
        }

        let addressBytes = Data(hexString: addressHex)
        let checksumBytes = try Data(bech32.convertBits(data: addressBytes.bytes, fromBits: 5, toBits: 8, pad: false))

        return bech32.encode(Constants.addressPrefix, values: checksumBytes)
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
