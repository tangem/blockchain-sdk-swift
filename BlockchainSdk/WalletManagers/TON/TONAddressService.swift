//
//  TONAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk

public class TONAddressService: AddressService {
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        try walletPublicKey.validateAsEdKey()
        return walletPublicKey.hexString
    }
    
    public func validate(_ address: String) -> Bool {
        return true
    }
    
}
