//
//  BitcoinTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import HDWalletKit
import BitcoinCoreSPV

class BitcoinTransactionBuilder {
	var unspentOutputs: [BtcTx]? {
		didSet {
			let utxoDTOs: [UtxoDTO]? = unspentOutputs?.map {
				return UtxoDTO(hash: Data(Data(hex: $0.tx_hash).reversed()),
							   index: $0.tx_output_n,
							   value: Int($0.value),
							   script: Data(hex: $0.script))
			}
			if let utxos = utxoDTOs {
				let spendingScripts: [Script] = walletScripts.compactMap { script in
					let chunks = script.scriptChunks.enumerated().map { (index, chunk) in
						Chunk(scriptData: script.data, index: index, payloadRange: chunk.range)
					}
					return Script(with: script.data, chunks: chunks)
				}
				bitcoinManager.fillBlockchainData(unspentOutputs: utxos, spendingScripts: spendingScripts)
			}
		}
	}
	
	var feeRates: [Decimal: Int] = [:]
    var bitcoinManager: BitcoinManager
    
    private var changeScript: Data?
	private let walletScripts: [HDWalletScript]

	init(bitcoinManager: BitcoinManager, addresses: [Address]) {
        self.bitcoinManager = bitcoinManager
        let scriptAddresses = addresses.map { $0 as? BitcoinScriptAddress }
        var script: Data?
        if scriptAddresses.count > 0 {
            if let scriptAddress = scriptAddresses.first(where: {
                if case .bitcoin(let t) = $0?.type {
                    return t == .bech32
                }
                return false
            }) {
                script = scriptAddress?.script.data
            }
        }
        walletScripts = scriptAddresses.compactMap { $0?.script }
        changeScript = script?.sha256()
	}
	
	public func buildForSign(transaction: Transaction) -> [Data]? {
		do {
			let hashes = try bitcoinManager.buildForSign(target: transaction.destinationAddress,
														 amount: transaction.amount.value,
                                                         feeRate: feeRates[transaction.fee.value]!,
                                                         changeScript: changeScript,
                                                         isReplacedByFee: false)
			return hashes
		} catch {
			print(error)
			return nil
		}
	}
	
	public func buildForSend(transaction: Transaction, signature: Data, hashesCount: Int) -> Data? {
		guard let signatures = splitSignatureAndConvertToDER(signature, hashesCount: hashesCount) else {
			return nil
		}
		
		do {
			return try bitcoinManager.buildForSend(target: transaction.destinationAddress,
												   amount: transaction.amount.value,
												   feeRate: feeRates[transaction.fee.value]!,
                                                   derSignatures: signatures,
                                                   changeScript: changeScript,
                                                   isReplacedByFee: false)
		} catch {
			print(error)
			return nil
		}
	}
	
	private func splitSignatureAndConvertToDER(_ signature: Data, hashesCount: Int) -> [Data]? {
		var derSigs = [Data]()
		for index in 0..<hashesCount {
			let offsetMin = index*64
			let offsetMax = offsetMin+64
			guard offsetMax <= signature.count else {
				return nil
			}
			
			let sig = signature[offsetMin..<offsetMax]
			guard let signDer = Secp256k1Utils.serializeToDer(secp256k1Signature: sig) else {
				return nil
			}
			
			derSigs.append(signDer)
		}
		
		return derSigs
	}
}
