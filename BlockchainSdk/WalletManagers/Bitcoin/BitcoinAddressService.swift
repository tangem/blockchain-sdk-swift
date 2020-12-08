//
//  BitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

public class BitcoinAddressService: AddressService {
    let legacy: BitcoinLegacyAddressService
    let bech32: BitcoinBech32AddressService
    
    init(networkParams: INetwork) {
        legacy = BitcoinLegacyAddressService(networkParams: networkParams)
        bech32 = BitcoinBech32AddressService(networkParams: networkParams)
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        return bech32.makeAddress(from: walletPublicKey)
    }
    
    public func validate(_ address: String) -> Bool {
        legacy.validate(address) || bech32.validate(address)
    }
    
    public func makeAddresses(from walletPublicKey: Data) -> [Address] {
        let bech32AddressString = bech32.makeAddress(from: walletPublicKey)
        let legacyAddressString = legacy.makeAddress(from: walletPublicKey)
      
        let bech32Address = BitcoinAddress(type: .bech32, value: bech32AddressString)
        
        let legacyAddress = BitcoinAddress(type: .legacy, value: legacyAddressString)
        
        return [bech32Address, legacyAddress]
    }
}


public class BitcoinLegacyAddressService: AddressService {
    private let converter: IAddressConverter

    init(networkParams: INetwork) {
        converter = Base58AddressConverter(addressVersion: networkParams.pubKeyHash, addressScriptVersion: networkParams.scriptHash)
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let publicKey = PublicKey(withAccount: 0,
                                  index: 0,
                                  external: true,
                                  hdPublicKeyData: walletPublicKey)
        
        let address = try! converter.convert(publicKey: publicKey, type: .p2pkh).stringValue
        
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
}


public class BitcoinBech32AddressService: AddressService {
    private let converter: IAddressConverter

    init(networkParams: INetwork) {
        let scriptConverter = ScriptConverter()
        converter = SegWitBech32AddressConverter(prefix: networkParams.bech32PrefixPattern, scriptConverter: scriptConverter)
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let compressedKey = Secp256k1Utils.convertKeyToCompressed(walletPublicKey)!
        let publicKey = PublicKey(withAccount: 0,
                                  index: 0,
                                  external: true,
                                  hdPublicKeyData: compressedKey)
        
        let address = try! converter.convert(publicKey: publicKey, type: .p2wpkh).stringValue
        
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
}
