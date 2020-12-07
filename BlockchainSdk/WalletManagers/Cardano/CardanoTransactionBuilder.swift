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
    var unspentOutputs: [AdaliteUnspentOutput]? = nil
    let kDecimalNumber: Int16 = 6
    let kProtocolMagic: UInt64 = 764824073
    let shelleyCard: Bool
    
    
    internal init(walletPublicKey: Data, shelleyCard: Bool) {
        self.walletPublicKey = walletPublicKey
        self.shelleyCard = shelleyCard
    }
    
	public func buildForSign(transaction: Transaction, walletAmount: Decimal, isEstimated: Bool) -> Result<(hash:Data, bodyItem: CBOR), Error> {
        let txBodyResult = buildTransactionBody(from: transaction, walletAmount: walletAmount, isEstimated: isEstimated)
        
        switch txBodyResult {
        case .failure(let error):
            return .failure(error)
        case .success(let bodyItem):
            let transactionBody = bodyItem.encode()
            guard let transactionHash = Sodium().genericHash.hash(message: transactionBody, outputLength: 32) else {
                return .failure(WalletError.failedToBuildTx)
            }
            
            return .success((hash: Data(transactionHash), bodyItem: bodyItem))
        }
    }
    
    public func buildForSend(bodyItem: CBOR, signature: Data) -> Result<Data, Error> {
        let witnessDataItem = shelleyCard ?
            CBOR.array([CBOR.array([CBOR.byteString(walletPublicKey.bytes),
                                    CBOR.byteString(signature.bytes)])])
            : CBOR.array([CBOR.array([CBOR.byteString(walletPublicKey.bytes),
                                      CBOR.byteString(signature.bytes),
                                      CBOR.byteString(Data(hexString: "0000000000000000000000000000000000000000000000000000000000000000").bytes),
                                      CBOR.byteString(Data(hexString: "A0").bytes)
            ])])
        
        let witnessMap = CBOR.map([CBOR.unsignedInt(shelleyCard ? 0 : 2) : witnessDataItem])
        let tx = CBOR.array([bodyItem, witnessMap, nil])
        let txForSend = tx.encode()
        return .success(Data(txForSend))
        
    }
	private func buildTransactionBody(from transaction: Transaction, walletAmount: Decimal, isEstimated: Bool = false) -> Result<CBOR, Error> {
        guard let unspentOutputs = self.unspentOutputs else {
            return .failure(CardanoError.noUnspents)
        }
        let convertValue = Blockchain.cardano(shelley: shelleyCard).decimalValue
        let feeConverted = transaction.fee.value * convertValue
        let amountConverted = transaction.amount.value * convertValue
        let walletAmountConverted = walletAmount * convertValue
        let change = walletAmountConverted - amountConverted - feeConverted
        let amountLong = (amountConverted.rounded() as NSDecimalNumber).uint64Value
        let changeLong = (change.rounded() as NSDecimalNumber).uint64Value
        let feesLong = (feeConverted.rounded() as NSDecimalNumber).uint64Value
        
        if !isEstimated && (amountLong < 1000000 || (changeLong < 1000000 && changeLong != 0)) {
            return .failure(CardanoError.lowAda)
        }
        
        guard let targetAddressBytes =  CardanoAddress.decode(transaction.destinationAddress)?.bytes else {
            return .failure(WalletError.failedToBuildTx)
        }
        
        var transactionMap = CBOR.map([:])
        var inputsArray = [CBOR]()
        for unspentOutput in unspentOutputs {
            let array = CBOR.array(
                [CBOR.byteString(Data(hexString: unspentOutput.id).bytes),
                 CBOR.unsignedInt(UInt64(unspentOutput.index))])
            inputsArray.append(array)
        }
        
        
        
        var outputsArray = [CBOR]()
        outputsArray.append(CBOR.array([CBOR.byteString(targetAddressBytes), CBOR.unsignedInt(amountLong)]))
           
        guard let changeAddressBytes =  CardanoAddress.decode(transaction.sourceAddress)?.bytes else {
            return .failure(WalletError.failedToBuildTx)
        }
        
        if (changeLong > 0) {
            outputsArray.append(CBOR.array([CBOR.byteString(changeAddressBytes), CBOR.unsignedInt(changeLong)]))
        }
        
        transactionMap[CBOR.unsignedInt(0)] = CBOR.array(inputsArray)
        transactionMap[CBOR.unsignedInt(1)] = CBOR.array(outputsArray)
        transactionMap[2] = CBOR.unsignedInt(feesLong)
        transactionMap[3] = CBOR.unsignedInt(90000000)
        
        return .success(transactionMap)
    }
}
