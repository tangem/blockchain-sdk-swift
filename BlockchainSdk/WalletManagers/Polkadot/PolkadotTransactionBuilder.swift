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
        /*
            Polkadot and Kusama indexes are taken from TrustWallet:
            https://github.com/trustwallet/wallet-core/blob/a771f38d3af112db7098730a5b0b9a1a9b65ca86/src/Polkadot/Extrinsic.cpp#L30

            Westend index is taken from the transaction made by Fearless iOS app

            This stuff can also be found in the sources. Look for `pallet_balances`.

            Polkadot:
            https://github.com/paritytech/polkadot/blob/3b68869e14f84b043aa65bd83f9fe44359e4d626/runtime/polkadot/src/lib.rs#L1341
            Kusama:
            https://github.com/paritytech/polkadot/blob/3b68869e14f84b043aa65bd83f9fe44359e4d626/runtime/kusama/src/lib.rs#L1375
            Westend:
            https://github.com/paritytech/polkadot/blob/3b68869e14f84b043aa65bd83f9fe44359e4d626/runtime/westend/src/lib.rs#L982
        */
        switch network {
        case .polkadot:
            return Data(hexString: "0x0500")
        case .kusama:
            return Data(hexString: "0x0400")
        case .westend:
            return Data(hexString: "0x0400")
        }
    }
    
    private let extrinsicFormat: UInt8 = 4
    private let signedBit: UInt8 = 0x80
    private let sigTypeEd25519: UInt8 = 0x00
    
    init(walletPublicKey: Data, network: PolkadotNetwork) {
        self.walletPublicKey = walletPublicKey
        self.blockchain = network.blockchain
        self.network = network
    }
    
    func buildForSign(amount: Amount, destination: String, meta: PolkadotBlockchainMeta) throws -> Data {
        let rawAddress = encodingRawAddress(specVersion: meta.specVersion)

        var message = Data()
        message.append(try encodeCall(amount: amount, destination: destination, rawAddress: rawAddress))
        message.append(try encodeEraNonceTip(era: meta.era, nonce: meta.nonce, tip: 0))
        message.append(try codec.encode(meta.specVersion))
        message.append(try codec.encode(meta.transactionVersion))
        message.append(Data(hexString: meta.genesisHash))
        message.append(Data(hexString: meta.blockHash))
        return message
    }
    
    func buildForSend(amount: Amount, destination: String, meta: PolkadotBlockchainMeta, signature: Data) throws -> Data {
        let rawAddress = encodingRawAddress(specVersion: meta.specVersion)

        let address = PolkadotAddress(publicKey: walletPublicKey, network: network)
        guard let addressBytes = address.bytes(raw: rawAddress) else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }
        
        var transactionData = Data()
        transactionData.append(Data(extrinsicFormat | signedBit))
        transactionData.append(addressBytes)
        transactionData.append(Data(sigTypeEd25519))
        transactionData.append(signature)
        transactionData.append(try encodeEraNonceTip(era: meta.era, nonce: meta.nonce, tip: 0))
        transactionData.append(try encodeCall(amount: amount, destination: destination, rawAddress: rawAddress))

        let messageLength = try messageLength(transactionData)
        transactionData = messageLength + transactionData
        
        return transactionData
    }
    
    private func encodeCall(amount: Amount, destination: String, rawAddress: Bool) throws -> Data {
        var call = Data()
        
        call.append(balanceTransferCallIndex)
        
        guard
            let address = PolkadotAddress(string: destination, network: network),
            let addressBytes = address.bytes(raw: rawAddress)
        else {
            throw BlockchainSdkError.failedToConvertPublicKey
        }
        call.append(addressBytes)
                        
        let decimalValue = amount.value * blockchain.decimalValue
        let intValue = BigUInt((decimalValue.rounded() as NSDecimalNumber).uint64Value)
        call.append(try SCALE.default.encode(intValue, .compact))
        
        return call
    }
    
    private func encodingRawAddress(specVersion: UInt32) -> Bool {
        switch network {
        case .polkadot:
            return specVersion < 28
        case .kusama:
            return specVersion < 2028
        case .westend:
            return false
        }
    }

    private func encodeEraNonceTip(era: PolkadotBlockchainMeta.Era?, nonce: UInt64, tip: UInt64) throws -> Data {
        var data = Data()
        
        if let era = era {
            let era = encodeEra(era)
            data.append(era)
        } else {
            // TODO: This is taken from WalletCore code but it doesn't work.
            // TODO: RPC error is returned: "Transaction has a bad signature".
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
        let length = UInt64(message.count)
        let encoded = try codec.encode(length, .compact)
        return encoded
    }
}
