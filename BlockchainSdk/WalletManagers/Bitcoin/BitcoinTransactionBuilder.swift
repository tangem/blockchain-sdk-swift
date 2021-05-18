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
import BitcoinCore

class BitcoinTransactionBuilder {
	var unspentOutputs: [BitcoinUnspentOutput]? {
		didSet {
			let utxoDTOs: [UtxoDTO]? = unspentOutputs?.map {
				return UtxoDTO(hash: Data(Data(hex: $0.transactionHash).reversed()),
							   index: $0.outputIndex,
							   value: Int($0.amount),
							   script: Data(hex: $0.outputScript))
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
            guard let feeRate = feeRates[transaction.fee.value] else { return nil }
            
			let hashes = try bitcoinManager.buildForSign(target: transaction.destinationAddress,
														 amount: transaction.amount.value,
                                                         feeRate: feeRate,
                                                         changeScript: changeScript,
                                                         isReplacedByFee: false)
			return hashes
		} catch {
			print(error)
			return nil
		}
	}
	
	public func buildForSend(transaction: Transaction, signatures: [Data]) -> Data? {
        guard let signatures = convertToDER(signatures),
              let feeRate = feeRates[transaction.fee.value] else {
			return nil
		}
		
		do {
			return try bitcoinManager.buildForSend(target: transaction.destinationAddress,
												   amount: transaction.amount.value,
												   feeRate: feeRate,
                                                   derSignatures: signatures,
                                                   changeScript: changeScript,
                                                   isReplacedByFee: false)
		} catch {
			print(error)
			return nil
		}
	}
	
	private func convertToDER(_ signatures: [Data]) -> [Data]? {
        var derSigs = [Data]()
        
        for signature in signatures {
            guard let signDer = Secp256k1Utils.serializeToDer(secp256k1Signature: signature) else {
                return nil
            }
            
            derSigs.append(signDer)
        }
    
		return derSigs
	}
}
