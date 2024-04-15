//
//  EthereumAddressUtils.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumAddressUtils {
    func toChecksumAddress(_ address: String) -> String? {
        let address = address.lowercased().removeHexPrefix()
        guard let hash = address.data(using: .utf8)?.sha3(.keccak256).hexString.lowercased().removeHexPrefix() else {
            return nil
        }

        var ret = "0x"
        let hashChars = Array(hash)
        let addressChars = Array(address)
        for i in 0 ..< addressChars.count {
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
