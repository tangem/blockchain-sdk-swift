//
//  DecimalUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/*
 Decimal Blockchain Address - d01clhamkvxw8ur9afuzxqhuvsrzelcl0x25j4asd
 DSC Address - 0xc7efddd98671f832f53c11817e3203167f8fbasd
 Legacy Address - dx1fv0m65st02p0z93xxarsd6g4ydltg8crm78hkv no use
 */

struct DecimalBlockchainAddressConverter {
    
    // MARK: - Private Properties
    
    private let bech32 = Bech32()
    
    // MARK: - Implementation
    
    func convertDscAddressToDecimalBlockchainAddress(addressHex: String) throws -> String {
        if addressHex.lowercased().hasPrefix(Constants.addressPrefix) || addressHex.lowercased().hasPrefix(Constants.legacyAddressPrefix) {
            return addressHex
        }

        let addressBytes = Data(hexString: addressHex)

        return bech32.encode(Constants.addressPrefix, values: addressBytes)
    }

    func convertDecimalBlockchainAddressToDscAddress(addressHex: String) throws -> String {
        if addressHex.hasHexPrefix() {
            return addressHex
        }
        
        let decodeValue = try bech32.decode(addressHex)
        
        let convertedAddressBytes = try bech32.convertBits(
            data: decodeValue.checksum.bytes,
            fromBits: 5,
            toBits: 8,
            pad: false
        )

        return convertedAddressBytes.toHexString().addHexPrefix()
    }
}

extension DecimalBlockchainAddressConverter {
    enum Constants {
        static let addressPrefix = "d0"
        static let legacyAddressPrefix = "dx"
    }
}
