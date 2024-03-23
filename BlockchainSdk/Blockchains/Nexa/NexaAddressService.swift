//
//  NexaAddressService.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

import class BitcoinCore.CashAddrBech32

public class NexaAddressService {
    private let prefix = "nexa"
    // We use 152 byte for get a "n" prefix
    private let p2khPrefixByte: UInt8 = UInt8(19<<3) // same as UInt8(152)
    
    init() {}
}

// MARK: - AddressProvider

@available(iOS 13.0, *)
extension NexaAddressService: AddressProvider {
    public func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let outputScript = try NexaScriptBuilder().outputScript(publicKey: publicKey.blockchainKey)
        let walletAddress = CashAddrBech32.encode(Data([p2khPrefixByte]) + outputScript, prefix: prefix)
        return PlainAddress(value: walletAddress, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator

@available(iOS 13.0, *)
extension NexaAddressService: AddressValidator {
    public func validate(_ address: String) -> Bool {
        let address = address.contains(":") ? address: "\(prefix):\(address)"
        
        let validStartLetters = ["q", "n"]
        
        guard let first = address.first,
              validStartLetters.contains(where: { $0 == String(first) }) else {
            return false
        }
        
        guard CashAddrBech32.decode(address) != nil else {
            return false
        }

        return true
    }
}
