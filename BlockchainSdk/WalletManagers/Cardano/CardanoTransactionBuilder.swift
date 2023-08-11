//
//  CardanoTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftCBOR
import Sodium
import TangemSdk

class CardanoTransactionBuilder {
    let walletPublicKey: Data
    var unspentOutputs: [CardanoUnspentOutput]? = nil
    let kDecimalNumber: Int16 = 6
    let kProtocolMagic: UInt64 = 764824073
    
    internal init(walletPublicKey: Data) {
        self.walletPublicKey = walletPublicKey
    }
    
	public func buildForSign(transaction: Transaction, walletAmount: Decimal, isEstimated: Bool) throws -> (hash:Data, bodyItem: CBOR)  {
        let bodyItem = try buildTransactionBody(from: transaction, walletAmount: walletAmount, isEstimated: isEstimated)
        let transactionBody = bodyItem.encode()
        guard let transactionHash = Sodium().genericHash.hash(message: transactionBody, outputLength: 32) else {
            throw WalletError.failedToBuildTx
        }
        
        return (hash: Data(transactionHash), bodyItem: bodyItem)
    }
    
    public func buildForSend(bodyItem: CBOR, signature: Data) throws -> Data {
        guard let unspents = unspentOutputs else {
            throw CardanoError.noUnspents
        }
        
        let useByronWitness = unspents.contains(where: { !CardanoAddressUtils.isShelleyAddress($0.address) })
        let useShelleyWitness = unspents.contains(where: { CardanoAddressUtils.isShelleyAddress($0.address) })

        var witnessMap = CBOR.map([:])
        if useShelleyWitness {
            witnessMap[0] = CBOR.array([CBOR.array([CBOR.byteString(walletPublicKey.bytes),
                                                    CBOR.byteString(signature.bytes)])])
        }
        if useByronWitness {
            witnessMap[2] = CBOR.array([CBOR.array([CBOR.byteString(walletPublicKey.bytes),
                                                    CBOR.byteString(signature.bytes),
                                                    CBOR.byteString(Data(repeating: 0, count: 32).bytes),
                                                    CBOR.byteString(Data(hexString: "A0").bytes)
                            ])])
        }
        
        let tx = CBOR.array([bodyItem, witnessMap, nil])
        let txForSend = tx.encode()
        return Data(txForSend)
    }
    
	private func buildTransactionBody(from transaction: Transaction, walletAmount: Decimal, isEstimated: Bool = false) throws -> CBOR {
        guard let unspentOutputs = self.unspentOutputs else {
            throw CardanoError.noUnspents
        }
        
        let convertValue = Blockchain.cardano(extended: false).decimalValue
        let feeConverted = transaction.fee.amount.value * convertValue
        let amountConverted = transaction.amount.value * convertValue
        let walletAmountConverted = walletAmount * convertValue
        let change = walletAmountConverted - amountConverted - feeConverted
        let amountLong = (amountConverted.rounded() as NSDecimalNumber).uint64Value
        let changeLong = (change.rounded() as NSDecimalNumber).uint64Value
        let feesLong = (feeConverted.rounded() as NSDecimalNumber).uint64Value
        
        if !isEstimated && (amountLong < 1000000 || (changeLong < 1000000 && changeLong != 0)) {
            throw CardanoError.lowAda
        }
        
        guard let targetAddressBytes = CardanoAddressUtils.decode(transaction.destinationAddress)?.bytes else {
            throw WalletError.failedToBuildTx
        }
        
        var transactionMap = CBOR.map([:])
        var inputsArray = [CBOR]()
        for unspentOutput in unspentOutputs {
            let array = CBOR.array(
                [CBOR.byteString(Data(hexString: unspentOutput.transactionHash).bytes),
                 CBOR.unsignedInt(UInt64(unspentOutput.outputIndex))])
            inputsArray.append(array)
        }
        
        
        
        var outputsArray = [CBOR]()
        outputsArray.append(CBOR.array([CBOR.byteString(targetAddressBytes), CBOR.unsignedInt(amountLong)]))
           
        guard let changeAddressBytes = CardanoAddressUtils.decode(transaction.sourceAddress)?.bytes else {
            throw WalletError.failedToBuildTx
        }
        
        if (changeLong > 0) {
            outputsArray.append(CBOR.array([CBOR.byteString(changeAddressBytes), CBOR.unsignedInt(changeLong)]))
        }
        
        transactionMap[CBOR.unsignedInt(0)] = CBOR.array(inputsArray)
        transactionMap[CBOR.unsignedInt(1)] = CBOR.array(outputsArray)
        transactionMap[2] = CBOR.unsignedInt(feesLong)
        
        // Transaction validity time. Currently we are using absolute values.
        // At 16 April 2023 was 90007700 slot number.
        // We need to rework this logic to use relative validity time. TODO: https://tangem.atlassian.net/browse/IOS-3471
        // This can be constructed using absolute ttl slot from `/metadata` endpoint.
        transactionMap[3] = CBOR.unsignedInt(190000000)
        
        return transactionMap
    }
}
