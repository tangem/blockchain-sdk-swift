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
import BitcoinCore

@available(iOS 13.0, *)
public class KaspaAddressService: AddressService {
    private let prefix = "kaspa"
    private let version: KaspaAddressComponents.KaspaAddressType = .P2PK_ECDSA
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let walletAddress = HDWalletKit.Bech32.encode(version.rawValue.data + compressedKey, prefix: prefix)
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        guard
            let components = parse(address),
            components.prefix == self.prefix
        else {
            return false
        }
        
        let validStartLetters = ["q", "p"]
        guard
            let firstAddressLetter = address.dropFirst(prefix.count + 1).first,
            validStartLetters.contains(String(firstAddressLetter))
        else {
            return false
        }
        
        return true
    }
    
    func parse(_ address: String) -> KaspaAddressComponents? {
        guard
            let (prefix, data) = CashAddrBech32.decode(address),
            !data.isEmpty,
            let firstByte = data.first,
            let type = KaspaAddressComponents.KaspaAddressType(rawValue: firstByte)
        else {
            return nil
        }

        return KaspaAddressComponents(
            prefix: prefix,
            type: type,
            hash: data.dropFirst()
        )
    }
}
