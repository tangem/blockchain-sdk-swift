//
//  BitcoinCashAddrService.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore
import HDWalletKit
import TangemSdk

@available(iOS 13.0, *)
public class BitcoinCashAddrService {
    private let addressPrefix: String

    public init(networkParams: INetwork) {
        addressPrefix = networkParams.bech32PrefixPattern
    }

    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let prefix = Data([UInt8(0x00)]) //public key hash
        let payload = compressedKey.sha256Ripemd160
        let walletAddress = HDWalletKit.Bech32.encode(prefix + payload, prefix: addressPrefix)
        return walletAddress
    }

    public func validate(_ address: String) -> Bool {
        return (try? BitcoinCashAddress(address)) != nil
    }
}
