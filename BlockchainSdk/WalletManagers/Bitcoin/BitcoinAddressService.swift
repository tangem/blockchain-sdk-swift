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

public class BitcoinAddressService: AddressService {
    let testnet: Bool
    var possibleFirstCharacters: [String] { ["1","2","3","n","m"] }
    
    init(testnet: Bool) {
        self.testnet = testnet
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let hash = walletPublicKey.sha256()
		let legacy = LegacyAddress(hash: hash, coin: .bitcoin, addressType: testnet ? .testnet : .pubkeyHash)
		return legacy.base58
    }
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty else { return false }
        
        if possibleFirstCharacters.contains(String(address.lowercased().first!)) {
            guard (26...35) ~= address.count else { return false }
            
        }
        else {
            let networkPrefix = testnet ? "tb" : "bc"
            guard let _ = try? SegWitBech32.decode(hrp: networkPrefix, addr: address) else { return false }
            
            return true
        }

        guard let decoded = address.base58DecodedData,
            decoded.count > 24 else {
                return false
        }
        let rip = decoded[0..<21]
        let kcv = rip.doubleSha256
        
        for i in 0..<4 {
            if kcv[i] != decoded[21+i] {
                return false
            }
        }
        
        if testnet && (address.starts(with: "1") || address.starts(with: "3")) {
            return false
        }
        
        return true
    }
	
	public func make1Of2MultisigAddresses(firstPublicKey: Data, secondPublicKey: Data) throws -> [Address] {
		guard let script = try create1Of2MultisigOutputScript(firstPublicKey: firstPublicKey, secondPublicKey: secondPublicKey) else {
			throw BlockchainSdkError.failedToCreateMultisigScript
		}
		let scriptHash = script.data.sha256()
		let legacy = LegacyAddress(hash: scriptHash, coin: .bitcoin, addressType: .scriptHash)
		let scriptAddress = BitcoinScriptAddress(script: script, value: legacy.base58, type: .p2sh)
		return [scriptAddress]
	}
	
	func getNetwork(_ testnet: Bool) -> Data {
		testnet ? Data([UInt8(0x6F)]) : Data([UInt8(0x00)])
	}
	
	private func create1Of2MultisigOutputScript(firstPublicKey: Data, secondPublicKey: Data) throws -> Script? {
		var pubKeys = try [firstPublicKey, secondPublicKey].map { (key: Data) throws -> PublicKey in
			guard let compressed = Secp256k1Utils.convertKeyToCompressed(key) else {
				throw BlockchainSdkError.failedToCreateMultisigScript
			}
			return PublicKey(uncompressedPublicKey: key, compressedPublicKey: compressed, coin: .bitcoin)
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
