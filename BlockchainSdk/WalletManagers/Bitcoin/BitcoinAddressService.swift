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
		let base58 = getBase58(from: hash)
        return base58
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
        let kcv = rip.sha256().sha256()
        
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
		guard let script = create1Of2MultisigOutputScript(firstPublicKey: firstPublicKey, secondPublicKey: secondPublicKey) else {
			throw BlockchainSdkError.failedToCreateMultisigScript
		}
		let scriptHash = script.data.sha256()
		let base58 = getBase58(from: scriptHash)
		let scriptAddress = BitcoinScriptAddress(script: script, value: base58, type: .legacy)
		return [scriptAddress]
	}
	
	private func create1Of2MultisigOutputScript(firstPublicKey: Data, secondPublicKey: Data) -> Script? {
		let keys: [Data] = firstPublicKey.lexicographicallyPrecedes(secondPublicKey) ?
			[firstPublicKey, secondPublicKey] :
			[secondPublicKey, firstPublicKey]
		var pubKeys = [PublicKey]()
		for key in keys {
			guard let compressed = Secp256k1Utils.convertKeyToCompressed(key) else { return nil }
			pubKeys.append(PublicKey(uncompressedPublicKey: key, compressedPublicKey: compressed, coin: .bitcoin))
		}
		return ScriptFactory.Standard.buildMultiSig(publicKeys: pubKeys, signaturesRequired: 1)
	}
    
    func getNetwork(_ testnet: Bool) -> Data {
        return testnet ? Data([UInt8(0x6F)]): Data([UInt8(0x00)])
    }
	
	private func getBase58(from hash: Data) -> String {
		let ripemd160Hash = RIPEMD160.hash(message: hash)
		let netSelectionByte = getNetwork(testnet)
		let entendedRipemd160Hash = netSelectionByte + ripemd160Hash
		let sha = entendedRipemd160Hash.sha256().sha256()
		let ripemd160HashWithChecksum = entendedRipemd160Hash + sha[..<4]
		let base58 = String(base58: ripemd160HashWithChecksum, alphabet: Base58String.btcAlphabet)
		return base58
	}
}

extension BitcoinAddressService: MultisigAddressProvider {
	public func makeAddress(from walletPublicKey: Data, with pairPublicKey: Data)  -> [Address] {
		do {
			return try make1Of2MultisigAddresses(firstPublicKey: walletPublicKey, secondPublicKey: pairPublicKey)
		} catch {
			print(error)
			return []
		}
	}
}
