//
//  BitcoinAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 06.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import HDWalletKit
import BitcoinCore

@available(iOS 13.0, *)
public class BitcoinAddressService: AddressService {
    let legacy: BitcoinLegacyAddressService
    let bech32: BitcoinBech32AddressService
    
    init(networkParams: INetwork) {
        legacy = BitcoinLegacyAddressService(networkParams: networkParams)
        bech32 = BitcoinBech32AddressService(networkParams: networkParams)
    }
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        return try bech32.makeAddress(from: walletPublicKey)
    }
    
    public func validate(_ address: String) -> Bool {
        legacy.validate(address) || bech32.validate(address)
    }
    
    public func makeAddresses(from walletPublicKey: Data) throws -> [Address] {
        let bech32AddressString = try bech32.makeAddress(from: walletPublicKey)
        let legacyAddressString = try legacy.makeAddress(from: walletPublicKey)
      
        let bech32Address = BitcoinAddress(type: .bech32, value: bech32AddressString)
        
        let legacyAddress = BitcoinAddress(type: .legacy, value: legacyAddressString)
        
        return [bech32Address, legacyAddress]
    }
	
	public func make1Of2MultisigAddresses(firstPublicKey: Data, secondPublicKey: Data) throws -> [Address] {
		guard let script = try create1Of2MultisigOutputScript(firstPublicKey: firstPublicKey, secondPublicKey: secondPublicKey) else {
			throw BlockchainSdkError.failedToCreateMultisigScript
		}
		let legacyAddressString = try legacy.makeMultisigAddress(from: script.data.sha256Ripemd160)
		let scriptAddress = BitcoinScriptAddress(script: script, value: legacyAddressString, type: .legacy)
		let bech32AddressString = try bech32.makeMultisigAddress(from: script.data.sha256())
		let bech32Address = BitcoinScriptAddress(script: script, value: bech32AddressString, type: .bech32)
		return [bech32Address, scriptAddress]
	}
	
	private func create1Of2MultisigOutputScript(firstPublicKey: Data, secondPublicKey: Data) throws -> HDWalletScript? {
		var pubKeys = try [firstPublicKey, secondPublicKey].map { (key: Data) throws -> HDWalletKit.PublicKey in
            let key = try Secp256k1Key(with: key)
            let compressed = try key.compress()
            let deCompressed = try key.decompress()
			return HDWalletKit.PublicKey(uncompressedPublicKey: deCompressed, compressedPublicKey: compressed, coin: .bitcoin)
		}
		pubKeys.sort(by: { $0.compressedPublicKey.lexicographicallyPrecedes($1.compressedPublicKey) })
		return ScriptFactory.Standard.buildMultiSig(publicKeys: pubKeys, signaturesRequired: 1)
	}
}


public class BitcoinLegacyAddressService: AddressService {
    private let converter: IAddressConverter

    init(networkParams: INetwork) {
        converter = Base58AddressConverter(addressVersion: networkParams.pubKeyHash, addressScriptVersion: networkParams.scriptHash)
    }
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        try walletPublicKey.validateAsSecp256k1Key()
        
        let publicKey = PublicKey(withAccount: 0,
                                  index: 0,
                                  external: true,
                                  hdPublicKeyData: walletPublicKey)
        
        let address = try converter.convert(publicKey: publicKey, type: .p2pkh).stringValue
        
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
		let address = try converter.convert(keyHash: scriptHash, type: .p2sh).stringValue
		
		return address
	}
}

@available(iOS 13.0, *)
public class BitcoinBech32AddressService: AddressService {
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
		print("Script hash hex: ", scriptHash.hex)
		let address = try converter.convert(scriptHash: scriptHash).stringValue
		
		return address
	}
}

extension BitcoinAddressService: MultisigAddressProvider {
	public func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data) throws -> [Address] {
        return try make1Of2MultisigAddresses(firstPublicKey: walletPublicKey, secondPublicKey: pairPublicKey)
	}
}
