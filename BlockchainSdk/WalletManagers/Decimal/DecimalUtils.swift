//
//  DecimalUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DecimalUtils {
    func convertDscAddressToErcAddress(addressHex: String) -> String? {
        let bech32 = Bech32()
        
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
        let bech32 = Bech32()
        
        if addressHex.starts(with:Constants.addressPrefix) || addressHex.starts(with: Constants.legacyAddressPrefix) {
            return addressHex
        }

        let addressBytes = Data(hexString: addressHex)
        let checksumBytes = try Data(bech32.convertBits(data: addressBytes.bytes, fromBits: 5, toBits: 8, pad: false))

        return bech32.encode(Constants.addressPrefix, values: checksumBytes)
    }
}

extension DecimalUtils {
    enum Constants {
        static let addressPrefix = "d0"
        static let legacyAddressPrefix = "dx"
        static let erc55AddressPrefix = "0x"
    }
}
