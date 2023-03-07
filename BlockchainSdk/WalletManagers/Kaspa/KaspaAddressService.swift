//
//  KaspaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 07.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import HDWalletKit

@available(iOS 13.0, *)
public class KaspaAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let addressPrefix = "kaspa"
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let payload = RIPEMD160.hash(message: compressedKey.sha256())
        let walletAddress = HDWalletKit.Bech32.encode(compressedKey, prefix: addressPrefix)
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        // TODO
        // TODO
        // TODO
        // TODO
        // TODO
        // TODO
        // TODO
        return true
    }
}
