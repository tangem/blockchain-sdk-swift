//
//  PolkadotTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 28.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import ScaleCodec

class PolkadotTransactionBuilder {
    private let walletPublicKey: Data
    private let blockchain: Blockchain
    private let network: PolkadotNetwork
    private let codec = SCALE.default
    
    private var balanceTransferCallIndex: Data {
        switch network {
        case .polkadot:
            return Data(hexString: "0x0500")
        case .kusama:
            return Data(hexString: "0x0400")
        case .westend:
            #warning("TODO")
            fatalError()
        }
    }
    
    init(walletPublicKey: Data, blockchain: Blockchain, network: PolkadotNetwork) {
        self.walletPublicKey = walletPublicKey
        self.blockchain = blockchain
        self.network = network
    }
    
    func buildForSign(transaction: Transaction, walletAmount: Decimal, isEstimated: Bool, meta: PolkadotBlockchainMeta) throws -> Data {
        var message = Data()
        message.append(try encodeCall(transaction: transaction))
        message.append(try encodeEraNonceTip(era: meta.era, nonce: meta.nonce, tip: 0))
        message.append(try codec.encode(meta.specVersion))
        message.append(try codec.encode(meta.transactionVersion))
        message.append(Data(hexString: meta.genesisHash))
        message.append(Data(hexString: meta.blockHash))
        return message
    }
    
    func buildForSend(meta: PolkadotBlockchainMeta, transaction: Transaction, signature: Data) throws -> Data {
        let extrinsicFormat: UInt8 = 4
        let signedBit: UInt8 = 0x80
        let sigTypeEd25519: UInt8 = 0x00
        
        var transactionData = Data()
        transactionData.append(Data(extrinsicFormat | signedBit))
        transactionData.append(walletPublicKey)
        transactionData.append(Data(sigTypeEd25519))
        transactionData.append(signature)
        transactionData.append(try encodeEraNonceTip(era: meta.era, nonce: meta.nonce, tip: 0))
        transactionData.append(try encodeCall(transaction: transaction))

        let messageLength = try messageLength(transactionData)
        transactionData = messageLength + transactionData
        
        return transactionData
    }
    
    private func encodeCall(transaction: Transaction) throws -> Data {
        var call = Data()
        
        call.append(balanceTransferCallIndex)
        
        // Raw account ID
        #warning("TODO")
        let addressChecksumLength = 2
        guard let addressData = transaction.destinationAddress.base58DecodedData?.dropLast(addressChecksumLength) else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }
        call.append(addressData)
                
        let value = BigUInt(NSDecimalNumber(decimal: transaction.amount.value * blockchain.decimalValue).uint64Value)
        let encodedValue = try SCALE.default.encode(value, .compact)
        call.append(encodedValue)
        
        return encodedValue
    }
    
    private func encodeEraNonceTip(era: PolkadotBlockchainMeta.Era?, nonce: UInt64, tip: UInt64) throws -> Data {
        var data = Data()
        
        if let era = era {
            let era = encodeEra(era)
            data.append(era)
        } else {
            #warning("TODO: check")
            data.append(try codec.encode(UInt64(0), .compact))
        }
        
        let nonce = try codec.encode(nonce, .compact)
        data.append(nonce)

        let tipData = try codec.encode(BigUInt(tip), .compact)
        data.append(tipData)
        
        return data
    }
           
    private func encodeEra(_ era: PolkadotBlockchainMeta.Era) -> Data {
        var calPeriod: UInt64 = UInt64(pow(2, ceil(log2(Double(era.period)))))
        calPeriod = min(max(calPeriod, UInt64(4)), UInt64(1) << 16);

        let phase = era.blockNumber % calPeriod
        let quantizeFactor = max(calPeriod >> UInt64(12), UInt64(1))
        let quantizedPhase = phase / quantizeFactor * quantizeFactor
        
        let trailingZeros = UInt64(calPeriod.trailingZeroBitCount)

        let encoded = min(15, max(1, trailingZeros - 1)) + (((quantizedPhase / quantizeFactor) << 4))
        return Data.init(UInt8(encoded & 0xff)) + Data.init(UInt8(encoded >> 8))
    }
    
    private func messageLength(_ message: Data) throws -> Data {
        let codec = SCALE.default
        let length: UInt64 = UInt64(message.count)
        let encoded = try codec.encode(length, .compact)
        return encoded
    }
}
