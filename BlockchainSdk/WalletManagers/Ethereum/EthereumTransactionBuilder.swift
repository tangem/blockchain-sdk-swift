//
//  EthereumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import web3swift
import TangemSdk

class EthereumTransactionBuilder {
    private let walletPublicKey: Data
    private let chainId: BigUInt
    
    private var web3Network: Networks { Networks.fromInt(Int(chainId)) }
    
    init(walletPublicKey: Data, chainId: Int) throws {
        self.walletPublicKey = try Secp256k1Key(with: walletPublicKey).decompress()
        self.chainId = BigUInt(chainId)
    }
    
    public func buildForSign(transaction: Transaction, nonce: Int) -> CompiledEthereumTransaction? {
        guard let parameters = transaction.params as? EthereumTransactionParams else {
            return nil
        }
        
        let nonceValue = BigUInt(parameters.nonce ?? nonce)
        let gasLimit = parameters.gasLimit
        let gasPrice = parameters.gasPrice
        let data = parameters.data ?? getData(for: transaction.amount, targetAddress: transaction.destinationAddress)
        let targetAddress = transaction.amount.type == .coin ? transaction.destinationAddress: transaction.contractAddress
        
        guard nonceValue >= 0 else {
            return nil
        }
        
        guard let amountValue = transaction.amount.bigUIntValue else {
            return nil
        }
        
        guard let data = data else {
            return nil
        }
        
        guard let targetAddress = targetAddress else {
            return nil
        }
        
        guard let ethereumAddress = EthereumAddress(targetAddress,
                                                    type: .normal,
                                                    ignoreChecksum: transaction.amount.type != .coin,
                                                    network: web3Network) else {
            return nil
        }
        
        let transaction = EthereumTransaction(
            nonce: nonceValue,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            to: ethereumAddress,
            value: transaction.amount.type == .coin ? amountValue : .zero,
            data: data,
            v: 0,
            r: 0,
            s: 0
        )
        
        guard let hashForSign = transaction.hashForSignature(chainID: chainId) else {
            return nil
        }
        
        return CompiledEthereumTransaction(transaction: transaction, hash: hashForSign)
    }
    
    public func buildForSend(transaction: EthereumTransaction, hash: Data, signature: Data) -> Data? {
        var transaction = transaction
        guard let unmarshalledSignature = try? Secp256k1Signature(with: signature).unmarshal(with: walletPublicKey, hash: hash) else {
            return nil
        }
        
        transaction.v = BigUInt(unmarshalledSignature.v)
        transaction.r = BigUInt(unmarshalledSignature.r)
        transaction.s = BigUInt(unmarshalledSignature.s)
        
        let encodedBytesToSend = transaction.encodeForSend(chainID: chainId)
        return encodedBytesToSend
    }
    
    func getData(for amount: Amount, targetAddress: String) -> Data? {
        if !amount.type.isToken {
            return Data()
        }
        
        guard let amountData = amount.encodedAligned else {
            return nil
        }
        
        guard let addressData = EthereumAddress(targetAddress, network: web3Network)?.addressData else {
            return nil
        }
        
        let prefixData = Data(hex: "a9059cbb000000000000000000000000")
        return prefixData + addressData + amountData
    }
}

extension EthereumTransaction {
    func encodeForSend(chainID: BigUInt? = nil) -> Data? {
        let encodeV = chainID == nil ? self.v :
            self.v - 27 + chainID! * 2 + 35
        
        let fields = [self.nonce, self.gasPrice, self.gasLimit, self.to.addressData, self.value, self.data, encodeV, self.r, self.s] as [AnyObject]
        return RLP.encode(fields)
    }
}
