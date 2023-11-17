//
//  DecimalUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import HDWalletKit

struct DecimalUtils {
    
    // MARK: - Private Properties
    
    private let bech32 = Bech32()
    
    // MARK: - Implementation
    
    func convertDscAddressToErcAddress(addressHex: String) -> String? {
        if addressHex.starts(with: Constants.erc55AddressPrefix) {
            return addressHex
        }
        
        guard 
            let decodeValue = try? bech32.decode(addressHex),
            let convertedAddressBytes = try? bech32.convertBits(
                data: decodeValue.checksum.bytes,
                fromBits: 5,
                toBits: 8,
                pad: false
            )
        else {
            return nil
        }

        return convertedAddressBytes.toHexString().addHexPrefix()
    }

    func convertErcAddressToDscAddress(addressHex: String) throws -> String {
        if addressHex.starts(with: Constants.addressPrefix) || addressHex.starts(with: Constants.legacyAddressPrefix) {
            return addressHex
        }

        let addressBytes = Data(hexString: addressHex)

        return bech32.encode(Constants.addressPrefix, values: addressBytes)
    }
}

extension DecimalUtils {
    enum Constants {
        static let addressPrefix = "d0"
        static let legacyAddressPrefix = "dx"
        static let erc55AddressPrefix = "0x"
    }
}
