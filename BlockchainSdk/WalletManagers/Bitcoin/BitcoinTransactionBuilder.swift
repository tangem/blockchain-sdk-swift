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
	let isTestnet: Bool
	let walletPublicKey: Data
	var unspentOutputs: [BtcTx]? {
		didSet {
			let utxoDTOs: [UtxoDTO]? = unspentOutputs?.map {
				return UtxoDTO(hash: Data(Data(hex: $0.tx_hash).reversed()),
							   index: $0.tx_output_n,
							   value: Int($0.value),
							   script: Data(hex: $0.script))
			}
			if let utxos = utxoDTOs {
				bitcoinManager.fillBlockchainData(unspentOutputs: utxos)
			}
		}
	}
	
	var feeRates: [Decimal: Int] = [:]
	var bitcoinManager: BitcoinManager!
	var blockchain: Blockchain { Blockchain.bitcoin(testnet: isTestnet) }
	
	private let walletAddresses: [Address]
	private let walletScripts: [HDWalletKit.Script]
	
	private var hdTransaction: HDWalletKit.Transaction?
	
	init(walletPublicKey: Data, isTestnet: Bool, addresses: [Address]) {
		self.walletPublicKey = walletPublicKey
		self.isTestnet = isTestnet
		self.walletAddresses = addresses
		walletScripts = addresses.map { $0 as? BitcoinScriptAddress }.compactMap { $0?.script }
	}
	
	public func buildForSign(transaction: Transaction) -> [Data]? {
		// HDWalletKit version
		guard let outputScript = buildOutputScript(address: transaction.sourceAddress) else {
			return nil
		}
		
		guard let unspents = buildUnspents(with: [outputScript]) else {
			return nil
		}
		
		let amountSatoshi = transaction.amount.value * blockchain.decimalValue
		let changeSatoshi = calculateChange(unspents: unspents, amount: transaction.amount.value, fee: transaction.fee.value)
		
		guard let hdTransaction = hdWalletTransaction(from: transaction, unspents: unspents, amount: amountSatoshi, change: changeSatoshi) else {
			return nil
		}
		
		self.hdTransaction = hdTransaction
		
		var hashes = [Data]()
		
		for (index, unspent) in hdTransaction.inputs.enumerated() {
			
			if let script = Script(data: unspent.signatureScript),
			   // Only .p2sh and .p2pkh are available. If you want to use another types you should update HDWalletKit
			   script.scriptType == .p2sh {
				guard
					let spendingScript = findSpendingScript(scriptPubKey: script),
					let hashedScript = try? hdTransaction.hashForSignature(index: index, script: spendingScript, type: SighashType.BTC.ALL)
				else {
					return nil
				}
				
				hashes.append(hashedScript)
			} else {
				//				guard var tx = buildTxBody(unspents: unspents,
				//										   amount: amountSatoshi,
				//										   change: changeSatoshi,
				//										   targetAddress: transaction.destinationAddress,
				//										   changeAddress: transaction.changeAddress,
				//										   index: index) else {
				//					return nil
				//				}
				//
				//				// We also have to write a hash type (sigHashType is actually an unsigned char). Sighash type ALL = 0100 0000
				//				let suffix = [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)]
				//				tx.append(contentsOf: suffix)
				//				let hash = tx.doubleSha256
				//				hashes.append(hash)
			}
		}
		
		// Bitcore version
		if hashes.count == 0 {
			do {
				let hashes = try bitcoinManager.buildForSign(target: transaction.destinationAddress,
															 amount: transaction.amount.value,
															 feeRate: feeRates[transaction.fee.value]!)
				self.hdTransaction = nil
				return hashes
			} catch {
				print(error)
				return nil
			}
		}
		
		return hashes
	}
	
	public func buildForSend(transaction: Transaction, signature: Data, hashesCount: Int) -> Data? {
		guard let unspentOutputs = unspentOutputs else {
			return nil
		}
		
		guard let signedHashes = extractSignedScripts(signature: signature, outputsCount: unspentOutputs.count) else {
			return nil
		}
		
		/// Parsed signed hashes
		let outputScripts = buildSignedScripts(signedHashes, publicKey: walletPublicKey)
		
		/// Signed hashes converted to unspents
		guard let unspents = buildUnspents(with: outputScripts) else {
			return nil
		}
		
		let amountSatoshi = transaction.amount.value * blockchain.decimalValue
		let changeSatoshi = calculateChange(unspents: unspents, amount: transaction.amount.value, fee: transaction.fee.value)
		
		func legacyTxBody() -> Data? {
			let tx = buildTxBody(unspents: unspents,
								 amount: amountSatoshi,
								 change: changeSatoshi,
								 targetAddress: transaction.destinationAddress,
								 changeAddress: transaction.changeAddress,
								 index: nil)
			return tx
		}
		
		if var hdTx = hdTransaction, hdTx.inputs.count == outputScripts.count {
			var inputs = [TransactionInput]()
			for (index, unspent) in hdTx.inputs.enumerated() {
				guard let script = Script(data: unspent.signatureScript) else {
					return nil
				}
				
				switch script.scriptType {
				case .p2sh:
					guard
						let spendingScript = findSpendingScript(scriptPubKey: script),
						spendingScript.isSentToMultisig,
						let newScriptData = ScriptFactory.MultiSig.createMultiSigInputScriptBytes(for: [signedHashes[index]], with: spendingScript)
					else {
						return nil
					}
					
					inputs.append(TransactionInput(previousOutput: unspent.previousOutput, signatureScript: newScriptData.data, sequence: unspent.sequence))
				case .p2wsh, .p2wpkh:
					return nil
				default:
					continue
				}
			}
			
			hdTransaction = nil
			
			if inputs.count == 0 {
				return legacyTxBody()
			} else {
				hdTx.inputs = inputs
			}
			return hdTx.serialized()
		} else {
			
			// Bitcore version
			guard let signatures = splitSignatureAndConvertToDER(signature, hashesCount: hashesCount) else {
				return nil
			}
			
			do {
				return try bitcoinManager.buildForSend(target: transaction.destinationAddress,
													   amount: transaction.amount.value,
													   feeRate: feeRates[transaction.fee.value]!,
													   derSignatures: signatures)
			} catch {
				print(error)
				return nil
			}
		}
	}
	
	// MARK: - Deprecated
	
	private func calculateChange(unspents: [UnspentTransaction], amount: Decimal, fee: Decimal) -> Decimal {
		let fullAmountSatoshi = Decimal(unspents.reduce(0, {$0 + $1.amount}))
		let feeSatoshi = fee * blockchain.decimalValue
		let amountSatoshi = amount * blockchain.decimalValue
		return fullAmountSatoshi - amountSatoshi - feeSatoshi
	}
	
	private func buildPrefix(for data: Data) -> Data {
		switch data.count {
		case 0..<Int(Op.pushData1.rawValue):
			return data.count.byte
		case Int(Op.pushData1.rawValue)..<Int(0xff):
			return Data([Op.pushData1.rawValue]) + data.count.byte
		case Int(0xff)..<Int(0xffff):
			return Data([Op.pushData2.rawValue]) + data.count.bytes2LE
		default:
			return Data([Op.pushData4.rawValue]) + data.count.bytes4LE
		}
	}
	
	private func buildTxBody(unspents: [UnspentTransaction], amount: Decimal, change: Decimal, targetAddress: String, changeAddress: String, index: Int?) -> Data? {
		var txToSign = Data()
		// version
		txToSign.append(contentsOf: [UInt8(0x01),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
		
		// number of unspents(inputs) 01
		txToSign.append(unspents.count.byte)
		
		//hex str hash prev btc
		// serialized unspents (inputs)
		for (inputIndex, input) in unspents.enumerated() {
			let hashKey: [UInt8] = input.hash.reversed()
			txToSign.append(contentsOf: hashKey)
			txToSign.append(contentsOf: input.outputIndex.bytes4LE)
			if (index == nil) || (inputIndex == index) {
				txToSign.append(input.outputScript.count.byte)
				txToSign.append(contentsOf: input.outputScript)
			} else {
				txToSign.append(UInt8(0x00))
			}
			// sequence - ffffffff
			txToSign.append(contentsOf: [UInt8(0xff),UInt8(0xff),UInt8(0xff),UInt8(0xff)])
		}
		
		// number of outputs 02
		let outputCount = change == 0 ? 1 : 2
		txToSign.append(outputCount.byte)
		
		//8 bytes
		txToSign.append(contentsOf: amount.bytes8LE)
		guard let outputScriptBytes = buildOutputScript(address: targetAddress) else {
			return nil
		}
		//hex str 1976a914....88ac
		txToSign.append(outputScriptBytes.count.byte)
		txToSign.append(contentsOf: outputScriptBytes)
		
		if change != 0 {
			//8 bytes
			txToSign.append(contentsOf: change.bytes8LE)
			//hex str 1976a914....88ac
			guard let outputScriptChangeBytes = buildOutputScript(address: changeAddress) else {
				return nil
			}
			txToSign.append(outputScriptChangeBytes.count.byte)
			txToSign.append(contentsOf: outputScriptChangeBytes)
		}
		// lock time - 00000000
		txToSign.append(contentsOf: [UInt8(0x00),UInt8(0x00),UInt8(0x00),UInt8(0x00)])
		
		return txToSign
	}
	
	private func buildSignedScripts(signature: Data, publicKey: Data, outputsCount: Int) -> [Data]? {
		guard let extracted = extractSignedScripts(signature: signature, outputsCount: outputsCount) else { return nil }
		
		return buildSignedScripts(extracted, publicKey: publicKey)
	}
	
	private func buildSignedScripts(_ scripts: [Data], publicKey: Data) -> [Data] {
		var newScripts = [Data]()
		scripts.forEach {
			var script = Data()
			script.append($0.count.byte)
			script.append($0)
			script.append(UInt8(0x41))
			script.append(contentsOf: publicKey)
			newScripts.append(script)
		}
		return newScripts
	}
	
	private func extractSignedScripts(signature: Data, outputsCount: Int) -> [Data]? {
		var scripts: [Data] = .init()
		scripts.reserveCapacity(outputsCount)
		for index in 0..<outputsCount {
			let offsetMin = index * 64
			let offsetMax = offsetMin + 64
			guard offsetMax <= signature.count else {
				return nil
			}
			
			let sig = signature[offsetMin..<offsetMax]
			guard let signDer = Secp256k1Utils.serializeToDer(secp256k1Signature: sig) else {
				return nil
			}
			
			var script = Data()
			script.append(contentsOf: signDer)
			
			// SigHash ALL = 0x01. Comment below - explanation from bitcoinj
			// A byte that controls which parts of a transaction are signed. This is exposed because signatures
			// parsed off the wire may have sighash flags that aren't "normal" serializations of the enum values.
			// Because Bitcoin Core works via bit testing, we must not lose the exact value when round-tripping
			// otherwise we'll fail to verify signature hashes.
			script.append(UInt8(0x1))
			scripts.append(script)
		}
		return scripts
	}
	
	private func hdWalletTransaction(from transaction: Transaction, unspents: [UnspentTransaction], amount: Decimal, change: Decimal) -> HDWalletKit.Transaction? {
		let hdWalletUnspents = unspents.map { HDWalletKit.TransactionInput(previousOutput: TransactionOutPoint(hash: Data($0.hash.reversed()), index: UInt32($0.outputIndex)), signatureScript: $0.outputScript, sequence: 0xFFFFFFFF) }
		var outputs = [TransactionOutput]()
		
		guard let destinationScript = buildOutputScript(address: transaction.destinationAddress) else { return nil }
		outputs.append(TransactionOutput(value: NSDecimalNumber(decimal: amount).uint64Value, lockingScript: destinationScript))
		
		if change != 0, let sourceScript = buildOutputScript(address: transaction.sourceAddress) {
			outputs.append(TransactionOutput(value: NSDecimalNumber(decimal: change).uint64Value, lockingScript: sourceScript))
		}
		let hdWalletTransaction = HDWalletKit.Transaction(version: 0x00000001,
														  inputs: hdWalletUnspents,
														  outputs: outputs,
														  lockTime: 0)
		return hdWalletTransaction
	}
	
	private func findSpendingScript(scriptPubKey: HDWalletKit.Script) -> HDWalletKit.Script? {
		guard let scriptHash = scriptPubKey.pushedData(at: 1) else { return nil }
		switch scriptHash.count {
		case 20:
			return walletScripts.first(where: { $0.data.sha256Ripemd160 == scriptHash })
		case 32:
			return walletScripts.first(where: { $0.data.sha256() == scriptHash })
		default:
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
	
	private func getOpCode(for data: Data) -> UInt8? {
		var opcode: UInt8
		
		if data.count == 0 {
			opcode = Op.op0.rawValue
		} else if data.count == 1 {
			let byte = data[0]
			if byte >= 1 && byte <= 16 {
				opcode = byte - 1 + Op.op1.rawValue
			} else {
				opcode = 1
			}
		} else if data.count < Op.pushData1.rawValue {
			opcode = UInt8(truncatingIfNeeded: data.count)
		} else if data.count < 256 {
			opcode = Op.pushData1.rawValue
		} else if data.count < 65536 {
			opcode = Op.pushData2.rawValue
		} else {
			return nil
		}
		
		return opcode
	}
	
	private func buildOutputScript(address: String) -> Data? {
		//segwit bech32
		if address.starts(with: "bc1") || address.starts(with: "tb1") {
			let networkPrefix = isTestnet ? "tb" : "bc"
			guard let segWitData = try? SegWitBech32.decode(hrp: networkPrefix, addr: address) else { return nil }
			
			let version = segWitData.version
			guard version >= 0 && version <= 16 else { return nil }
			
			var script = Data()
			script.append(version == 0 ? Op.op0.rawValue : version - 1 + Op.op1.rawValue) //smallNum
			let program = segWitData.program
			if program.count == 0 {
				script.append(Op.op0.rawValue) //smallNum
			} else {
				guard let opCode = getOpCode(for: program) else { return nil }
				if opCode < Op.pushData1.rawValue {
					script.append(opCode)
				} else if opCode == Op.pushData1.rawValue {
					script.append(Op.pushData1.rawValue)
					script.append(program.count.byte)
				} else if opCode == Op.pushData2.rawValue {
					script.append(Op.pushData2.rawValue)
					script.append(contentsOf: program.count.bytes2LE) //little endian
				} else if opCode == Op.pushData4.rawValue {
					script.append(Op.pushData4.rawValue)
					script.append(contentsOf: program.count.bytes4LE)
				}
				script.append(contentsOf: program)
			}
			return script
		}
		
		guard let decoded = address.base58DecodedData else {
			return nil
		}
		
		let first = decoded[0]
		let data = decoded[1...20]
		//P2H
		if (first == 0 || first == 111 || first == 48 || first == 49) { //0 for BTC/BCH 1 address | 48 for LTC L address
			return [Op.dup.rawValue, Op.hash160.rawValue ] + buildPrefix(for: data) + data + [Op.equalVerify.rawValue, Op.checkSig.rawValue]
		}
		//P2SH
		if(first == 5 || first == 0xc4 || first == 50) { //5 for BTC/BCH/LTC 3 address | 50 for LTC M address
			return [Op.hash160.rawValue] + buildPrefix(for: data) + data + [Op.equal.rawValue]
		}
		return nil
	}
	
	private func buildUnspents(with outputScripts:[Data]) -> [UnspentTransaction]? {
		let unspentTransactions: [UnspentTransaction]? = unspentOutputs?.enumerated().compactMap({ index, txRef  in
			let hash = Data(hex: txRef.tx_hash)
			let outputScript = outputScripts.count == 1 ? outputScripts.first! : outputScripts[index]
			return UnspentTransaction(amount: txRef.value, outputIndex: txRef.tx_output_n, hash: hash, outputScript: outputScript)
		})
		
		return unspentTransactions
	}
}
