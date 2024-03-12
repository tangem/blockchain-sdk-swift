//
//  RadiantUtils.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

struct RadiantUtils {
    func prepareWallet(address: String) throws -> String {
        guard let addressKeyHash = WalletCore.BitcoinAddress(string: address)?.keyhash else {
            throw WalletError.empty
        }
        
        let scriptHashData = WalletCore.BitcoinScript.buildPayToPublicKeyHash(hash: addressKeyHash).data
        
        return Data(scriptHashData.sha256().reversed()).hexString
    }
}
