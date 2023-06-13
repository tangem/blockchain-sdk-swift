//
//  WalletCoreTransactionCollector.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BitcoinCore
import TangemSdk

/// The structure of a transaction
/// https://www.oreilly.com/library/view/mastering-bitcoin/9781491902639/ch05.html
///
///
class TestUTXOTransactionCollector {
//    private var feeRates: [Decimal: Int] = [:]
//    private var outputs: [BitcoinUnspentTransaction] = []

    let tw: UTXOTransactionBuilder
    let bc: UTXOTransactionBuilder

    init(tw: UTXOTransactionBuilder, bc: UTXOTransactionBuilder) {
        self.tw = tw
        self.bc = bc
    }
}

extension TestUTXOTransactionCollector: UTXOTransactionBuilder {
    func update(unspentOutputs: [BitcoinUnspentOutput]) {
        print("walletCore unspentOutputs ->>", unspentOutputs)

        tw.update(unspentOutputs: unspentOutputs)
        bc.update(unspentOutputs: unspentOutputs)
    }

    func update(feeRates: [Decimal : Int]) {
        tw.update(feeRates: feeRates)
        bc.update(feeRates: feeRates)
    }

    func fee(for value: Decimal, address: String?, feeRate: Int, senderPay: Bool, changeScript: Data?, sequence: Int?) -> Decimal {
        let bcfee = bc.fee(for: value, address: address, feeRate: feeRate, senderPay: senderPay, changeScript: changeScript, sequence: sequence)
        let twfee = tw.fee(for: value, address: address, feeRate: feeRate, senderPay: senderPay, changeScript: changeScript, sequence: sequence)

        print("walletCore fee ->> bc", bcfee, "->> tw", twfee)

        return twfee
    }

    func buildForSign(transaction: Transaction, sequence: Int?, sortType: TransactionDataSortType) throws -> [Data] {
        let bchashes = try bc.buildForSign(transaction: transaction, sequence: sequence, sortType: sortType)
        let twhashes = try tw.buildForSign(transaction: transaction, sequence: sequence, sortType: sortType)

        print("walletCore bchashes ->>", bchashes.map { $0.hex }.joined(separator: "\n"))
        print("walletCore twhashes ->>", twhashes.map { $0.hex }.joined(separator: "\n"))

        return twhashes
    }

    func buildForSend(transaction: Transaction, signatures: [Signature], sequence: Int?, sortType: TransactionDataSortType) throws -> Data {
        let bchash = try bc.buildForSend(transaction: transaction, signatures: signatures, sequence: sequence, sortType: sortType)
        let twhash = try tw.buildForSend(transaction: transaction, signatures: signatures, sequence: sequence, sortType: sortType)

        print("walletCore bchash ->>", bchash.hex)
        print("walletCore twhash ->>", twhash.hex)
        //        assertionFailure()
        return twhash
    }
}

class WalletCoreUTXOTransactionCollector {
    private var feeRates: [Decimal: Int] = [:]
    private var outputs: [BitcoinUnspentOutput] = []

    private let coinRate: Decimal = pow(10, 8)
    private let coinType: CoinType
    //    private let publicKey: Data
    private let publicKey: WalletCore.PublicKey

    init(coinType: CoinType, publicKey: Data) {
        self.coinType = coinType
        self.publicKey = WalletCore.PublicKey(data: publicKey, type: .secp256k1)!
    }

    private func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate

        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
    }

    private func input(value: Decimal, feeRate: Int64, destinationAddress: String, changeAddress: String) throws -> BitcoinSigningInput {
        var input = BitcoinSigningInput.with {
            $0.coinType = coinType.rawValue
            $0.hashType = BitcoinScript.hashTypeForCoin(coinType: coinType)
            $0.amount = Int64(convertToSatoshi(value: value))
            $0.byteFee = Int64(feeRate)
            $0.useMaxAmount = false
            $0.toAddress = destinationAddress
            $0.changeAddress = changeAddress
        }

        input.utxo = outputs.map { output in
            let outPoint = BitcoinOutPoint.with {
                $0.hash = Data(Data(hexString: output.transactionHash).reversed())
                $0.index = UInt32(output.outputIndex)
                $0.sequence = 0 // UInt32.max
            }

            return BitcoinUnspentTransaction.with { utxo in
                utxo.amount = Int64(output.amount)
                utxo.script = Data(hexString: output.outputScript)
                utxo.outPoint = outPoint
            }
        }

        // we work with P2PKH
        // Pay To Public Key Hash
//        let address = AnyAddress(publicKey: publicKey, coin: coinType)
//        let utxoScript = BitcoinScript.lockScriptForAddress(address: address.description, coin: coinType)
//        let keyHash: Data = utxoScript.matchPayToPubkeyHash()!
//        let redeemScript = BitcoinScript.buildPayToPublicKeyHash(hash: keyHash)

//        input.scripts[keyHash.hexString] = redeemScript.data

        let plan: BitcoinTransactionPlan = AnySigner.plan(input: input, coin: coinType)
        input.plan = plan

        return input
    }

    private func input(transaction: Transaction) throws -> BitcoinSigningInput {
        guard let feeRate = feeRates[transaction.fee.amount.value] else {
            throw WalletError.failedToBuildTx
        }

        let value = transaction.amount.value
        let destinationAddress = transaction.destinationAddress
        let changeAddress = transaction.changeAddress

        var input = BitcoinSigningInput.with {
            $0.coinType = coinType.rawValue
            $0.hashType = BitcoinScript.hashTypeForCoin(coinType: coinType)
            $0.amount = Int64(convertToSatoshi(value: value))
            $0.byteFee = Int64(feeRate)
            $0.useMaxAmount = false
            $0.toAddress = destinationAddress
            $0.changeAddress = changeAddress
        }

        input.utxo = outputs.map { output in
            let outPoint = BitcoinOutPoint.with {
                $0.hash =  Data(Data(hexString: output.transactionHash).reversed())
                $0.index = UInt32(output.outputIndex)
                $0.sequence = 0 // UInt32.max
            }

            return BitcoinUnspentTransaction.with { utxo in
                utxo.amount = Int64(output.amount)
                utxo.script = Data(hexString: output.outputScript)
                utxo.outPoint = outPoint
            }
        }

        // we work with P2PKH
        // Pay To Public Key Hash
        let address = AnyAddress(publicKey: publicKey, coin: coinType)
        let utxoScript = BitcoinScript.lockScriptForAddress(address: address.description, coin: coinType)
        let keyHash: Data = utxoScript.matchPayToPubkeyHash()!
        let redeemScript = BitcoinScript.buildPayToPublicKeyHash(hash: keyHash)

//        print("walletCore address ->>", address.description)
//        print("walletCore utxoScript ->>", utxoScript.data.hex)

//        input.scripts[keyHash.hexString] = redeemScript.data

        let plan: BitcoinTransactionPlan = AnySigner.plan(input: input, coin: coinType)
//        print("walletCore plan ->>", plan.debugDescription)
//        print("walletCore input ->>", input.debugDescription)

        input.plan = plan

        return input
    }
}

extension WalletCoreUTXOTransactionCollector: UTXOTransactionBuilder {
    func update(unspentOutputs: [BitcoinUnspentOutput]) {
        outputs = unspentOutputs
    }

    func update(feeRates: [Decimal : Int]) {
        self.feeRates = feeRates
    }

    func fee(for value: Decimal, address: String?, feeRate: Int, senderPay: Bool, changeScript: Data?, sequence: Int?) -> Decimal {
        guard let address else {
            fatalError()
        }

        let input = try! input(value: value, feeRate: Int64(feeRate), destinationAddress: address, changeAddress: address)
        return Decimal(input.plan.fee) / coinRate
    }

    func buildForSign(transaction: Transaction, sequence: Int?, sortType: TransactionDataSortType) throws -> [Data] {
        let input = try input(transaction: transaction)

        // Serialize input
        let txInputData = try input.serializedData()

        // Step 2: Obtain preimage hashes
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput: BitcoinPreSigningOutput = try BitcoinPreSigningOutput(serializedData: preImageHashes)

        let hashes = preSigningOutput.hashPublicKeys.map { $0.dataHash }

//        print("walletCore txInputData ->>", txInputData.hexString)
//        print("walletCore preImageHashes ->>", txInputData.hexString)

        assert(preSigningOutput.hashPublicKeys.allSatisfy { $0.publicKeyHash == publicKey.bitcoinKeyHash })
        print("walletCore error ->>", preSigningOutput.error)
        print("walletCore hashes ->>", hashes.map { $0.hex })

        return hashes
    }

    func buildAndSign(transaction: Transaction, signer: WalletCoreSigner) throws -> Data {
        let input = try input(transaction: transaction)
        let output: BitcoinSigningOutput = try AnySigner.signExternally(input: input, coin: coinType, signer: signer)

        print("walletCore error ->>", output.error)
        print("walletCore transactionID ->>", output.transactionID)

        return output.encoded
    }

    func buildForSend(transaction: Transaction, signatures: [Signature], sequence: Int?, sortType: TransactionDataSortType) throws -> Data {
        //        let signatures = try convertToDER(signatures)

        print("walletCore signatures ->>", signatures)

        let input = try input(transaction: transaction)

        let txInputData = try input.serializedData()
        let signatureVec = DataVector()
        let pubkeyVec = DataVector()
        let utils = Secp256k1Utils()

        try signatures.forEach { signature in
            let der = try utils.serializeDer(signature.signature)
            assert(publicKey.verifyAsDER(signature: der, message: signature.hash))
            assert(publicKey.verify(signature: signature.signature, message: signature.hash))

            print("walletCore verifyAsDER ->>", publicKey.verifyAsDER(signature: der, message: signature.hash))
            print("walletCore verify ->>", publicKey.verify(signature: signature.signature, message: signature.hash))

            signatureVec.add(data: der)
        }

        pubkeyVec.add(data: publicKey.data)

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatureVec,
            publicKeys: pubkeyVec
        )

        let output: BitcoinSigningOutput = try BitcoinSigningOutput(serializedData: compileWithSignatures)

        print("walletCore buildForSend error ->>", output.error)
        print("walletCore buildForSend transactionID ->>", output.transactionID)
        print("walletCore encoded transaction ->>", output.encoded.hex)

        assert(output.error == .ok)

        return output.encoded
    }

    func convertToDER(_ signatures: [Signature]) throws -> [Data] {
        let utils = Secp256k1Utils()

        return try signatures.map {
            try utils.serializeDer($0.signature)
        }
    }
}

struct Signature: CustomStringConvertible {
    let hash: Data
    let publicKey: Data
    let signature: Data

    var description: String {
        "hash -- " + hash.hex + "\n" +
        "publicKey -- " + publicKey.hex + "\n" +
        "signature -- " + signature.hex
    }
}
