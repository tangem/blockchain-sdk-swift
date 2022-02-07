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
    
    public func buildForSign(transaction: Transaction, nonce: Int, gasLimit: BigUInt) -> (hash: Data, transaction: EthereumTransaction)? {
        let params = transaction.params as? EthereumTransactionParams
        let nonceValue = BigUInt(params?.nonce ?? nonce)
        
        guard nonceValue >= 0 else {
            return nil
        }
        
        guard let feeValue = Web3.Utils.parseToBigUInt("\(transaction.fee.value)", decimals: transaction.fee.decimals),
            let amountValue = Web3.Utils.parseToBigUInt("\(transaction.amount.value)", decimals: transaction.amount.decimals) else {
                return nil
        }
        
        guard let data = params?.data ?? getData(for: transaction.amount, targetAddress: transaction.destinationAddress) else {
            return nil
        }
        
        guard let targetAddr = transaction.amount.type == .coin ? transaction.destinationAddress: transaction.contractAddress else {
            return nil
        }
        
        guard let transaction = EthereumTransaction(amount: transaction.amount.type == .coin ? amountValue : BigUInt.zero,
                                                    fee: feeValue,
                                                    targetAddress: targetAddr,
                                                    nonce: nonceValue,
                                                    gasLimit: params?.gasLimit ?? gasLimit,
                                                    data: data,
                                                    ignoreCheckSum: transaction.amount.type != .coin,
                                                    network: web3Network) else {
                                                        return nil
        }
        
        guard let hashForSign = transaction.hashForSignature(chainID: chainId) else {
            return nil
        }
        
        return (hashForSign, transaction)
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
        
        guard let amountValue = Web3.Utils.parseToBigUInt("\(amount.value)", decimals: amount.decimals) else {
            return nil
        }
        
        var amountString = String(amountValue, radix: 16).remove("0X")
        while amountString.count < 64 {
            amountString = "0" + amountString
        }
        
        let amountData = Data(hex: amountString)
        
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
    
    init?(amount: BigUInt, fee: BigUInt, targetAddress: String, nonce: BigUInt, gasLimit: BigUInt = 21000, data: Data, ignoreCheckSum: Bool,
          v: BigUInt = 0, r: BigUInt = 0, s: BigUInt = 0, network: Networks) {
        let gasPrice = fee / gasLimit
        
        guard let ethAddress = EthereumAddress(targetAddress, type: .normal, ignoreChecksum: ignoreCheckSum, network: network) else {
            return nil
        }
        
        self.init(nonce: nonce,
                  gasPrice: gasPrice,
                  gasLimit: gasLimit,
                  to: ethAddress,
                  value: amount,
                  data: data,
                  v: v,
                  r: r,
                  s: s)
    }
}
