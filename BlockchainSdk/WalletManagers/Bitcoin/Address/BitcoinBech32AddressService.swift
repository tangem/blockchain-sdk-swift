//
//  BitcoinBech32AddressService.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore
import TangemSdk

@available(iOS 13.0, *)
public class BitcoinBech32AddressService {
    private let converter: SegWitBech32AddressConverter

    init(networkParams: INetwork) {
        let scriptConverter = ScriptConverter()
        converter = SegWitBech32AddressConverter(prefix: networkParams.bech32PrefixPattern, scriptConverter: scriptConverter)
    }

    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let publicKey = PublicKey(withAccount: 0,
                                  index: 0,
                                  external: true,
                                  hdPublicKeyData: compressedKey)

        let address = try converter.convert(publicKey: publicKey, type: .p2wpkh).stringValue

        return address
    }

    public func validate(_ address: String) -> Bool {
        do {
            _ = try converter.convert(address: address)
            return true
        } catch {
            return false
        }
    }

    public func makeMultisigAddress(from scriptHash: Data) throws -> String {
        let address = try converter.convert(scriptHash: scriptHash).stringValue

        return address
    }
}
