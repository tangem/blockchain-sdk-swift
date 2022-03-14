//
//  BitcoinCashAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 14.02.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import HDWalletKit
import TangemSdk
import BitcoinCore

@available(iOS 13.0, *)
public class BitcoinCashAddressService: AddressService {
    private let legacyService: BitcoinLegacyAddressService
    private let cashAddrService: CashAddrService
    
    public init(networkParams: INetwork) {
        self.legacyService = .init(networkParams: networkParams)
        self.cashAddrService = .init(networkParams: networkParams)
    }
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        try cashAddrService.makeAddress(from: walletPublicKey)
    }
    
    public func makeAddresses(from walletPublicKey: Data) throws -> [Address] {
        let cashAddrString = try makeAddress(from: walletPublicKey)
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let legacyString = try legacyService.makeAddress(from: compressedKey)
        
        let cashAddr = PlainAddress(value: cashAddrString, type: .default)
        let legacy = PlainAddress(value: legacyString, type: .legacy)
        
        return [cashAddr, legacy]
    }
    
    public func validate(_ address: String) -> Bool {
        cashAddrService.validate(address) || legacyService.validate(address)
    }
}

@available(iOS 13.0, *)
public class CashAddrService: AddressService {
    private let addressPrefix: String
    
    public init(networkParams: INetwork) {
        addressPrefix = networkParams.bech32PrefixPattern
    }
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let compressedKey = try Secp256k1Key(with: walletPublicKey).compress()
        let prefix = Data([UInt8(0x00)]) //public key hash
        let payload = RIPEMD160.hash(message: compressedKey.sha256())
        let walletAddress = HDWalletKit.Bech32.encode(prefix + payload, prefix: addressPrefix)
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        return (try? BitcoinCashAddress(address)) != nil
    }
}
