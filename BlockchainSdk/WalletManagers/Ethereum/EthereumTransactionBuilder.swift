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
    
    public func buildForSign(transaction: Transaction, nonce: Int, gasLimit: BigUInt?) -> (hash: Data, transaction: EthereumTransaction)? {
        let params = transaction.params as? EthereumTransactionParams
        let nonceValue = BigUInt(params?.nonce ?? nonce)
        
        guard nonceValue >= 0 else {
            return nil
        }
        
        guard let gasLimit = params?.gasLimit ?? gasLimit else {
            return nil
        }
        
        guard let feeValue = transaction.fee.bigUIntValue, let amountValue = transaction.amount.bigUIntValue else {
            return nil
        }
        
        guard let data = params?.data ?? getData(for: transaction.amount, targetAddress: transaction.destinationAddress) else {
            return nil
        }
        
        guard let targetAddr = transaction.amount.type == .coin ? transaction.destinationAddress: transaction.contractAddress else {
            return nil
        }
        

        
        guard let ethAddress = EthereumAddress(targetAddr,
                                               type: .normal,
                                               ignoreChecksum: transaction.amount.type != .coin,
                                               network: web3Network) else {
            return nil
        }
        
        
        let gasPrice = params?.gasPrice ?? feeValue / gasLimit
        
        let transaction = EthereumTransaction(nonce: nonceValue,
                                              gasPrice: gasPrice,
                                              gasLimit: gasLimit,
                                              to: ethAddress,
                                              value: transaction.amount.type == .coin ? amountValue : .zero,
                                              data: data,
                                              v: 0,
                                              r: 0,
                                              s: 0)
        
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
