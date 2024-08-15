//
//  TronUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 03.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct TronUtils {
    func combineBigUIntValueAtBalance(response constantResult: [String]) throws -> BigUInt {
        guard let hexValue = constantResult.first else {
            throw WalletError.failedToParseNetworkResponse()
        }
        
        // Need use 32 byte for obtain right value
        let substringHexSizeValue = String(hexValue.prefix(64))
        let bigIntValue = BigUInt(Data(hex: substringHexSizeValue))
        
        return bigIntValue
    }

    func convertAddressToBytes(_ base58String: String) throws -> Data {
        guard let bytes = base58String.base58CheckDecodedBytes else {
            throw TronUtilsError.failedToDecodeAddress
        }

        return Data(bytes)
    }
}

enum TronUtilsError: Error {
    case failedToDecodeAddress
}
