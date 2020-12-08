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
	
	public func make1Of2MultisigAddresses(firstPublicKey: Data, secondPublicKey: Data) throws -> [Address] {
		guard let script = try create1Of2MultisigOutputScript(firstPublicKey: firstPublicKey, secondPublicKey: secondPublicKey) else {
			throw BlockchainSdkError.failedToCreateMultisigScript
		}
		let scriptHash = script.data.sha256()
		let legacy = HDWalletKit.LegacyAddress(hash: scriptHash, coin: .bitcoin, addressType: .scriptHash)
		let scriptAddress = BitcoinScriptAddress(script: script, value: legacy.base58, type: .legacy)
		return [scriptAddress]
	}
	
	func getNetwork(_ testnet: Bool) -> Data {
		testnet ? Data([UInt8(0x6F)]) : Data([UInt8(0x00)])
	}
	
	private func create1Of2MultisigOutputScript(firstPublicKey: Data, secondPublicKey: Data) throws -> HDWalletKit.Script? {
		var pubKeys = try [firstPublicKey, secondPublicKey].map { (key: Data) throws -> HDWalletKit.PublicKey in
			guard let compressed = Secp256k1Utils.convertKeyToCompressed(key) else {
				throw BlockchainSdkError.failedToCreateMultisigScript
			}
			return HDWalletKit.PublicKey(uncompressedPublicKey: key, compressedPublicKey: compressed, coin: .bitcoin)
		}
		pubKeys.sort(by: { $0.compressedPublicKey.lexicographicallyPrecedes($1.compressedPublicKey) })
		return ScriptFactory.Standard.buildMultiSig(publicKeys: pubKeys, signaturesRequired: 1)
	}
	
//	func getNetwork(_ testnet: Bool, p2SH: Bool) -> Data {
//        return testnet ? Data([UInt8(0x6F)]) :
//			p2SH ? Data([UInt8(0x05)]) : Data([UInt8(0x00)])
//    }
//
//	private func getBase58(from hash: Data, p2sh: Bool = false) -> String {
//		let ripemd160Hash = RIPEMD160.hash(message: hash)
//		let netSelectionByte = getNetwork(testnet, p2SH: p2sh)
//		let entendedRipemd160Hash = netSelectionByte + ripemd160Hash
//		let sha = entendedRipemd160Hash.sha256().sha256()
//		let ripemd160HashWithChecksum = entendedRipemd160Hash + sha[..<4]
//		let base58 = String(base58: ripemd160HashWithChecksum, alphabet: Base58String.btcAlphabet)
//		return base58
//	}
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

extension BitcoinAddressService: MultisigAddressProvider {
	public func makeAddresses(from walletPublicKey: Data, with pairPublicKey: Data) -> [Address]? {
		do {
			return try make1Of2MultisigAddresses(firstPublicKey: walletPublicKey, secondPublicKey: pairPublicKey)
		} catch {
			print(error)
			return nil
		}
	}
}
