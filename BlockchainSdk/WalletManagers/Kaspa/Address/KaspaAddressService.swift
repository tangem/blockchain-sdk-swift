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
    private let addressPrefix = "kaspa"
    private let versionPrefix: UInt8 = 1
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let prefix = Data([versionPrefix])
        
        let walletAddress = HDWalletKit.Bech32.encode(prefix + compressedKey, prefix: addressPrefix)
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        guard
            let (addressPrefix, addressData) = HDWalletKit.Bech32.decode(address),
            addressPrefix == self.addressPrefix
        else {
            return false
        }
        
        let versionPrefix = addressData[0]
        guard versionPrefix == self.versionPrefix else {
            return false
        }
        
        let key = try? Secp256k1Key(with: addressData.dropFirst())
        return key != nil
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
