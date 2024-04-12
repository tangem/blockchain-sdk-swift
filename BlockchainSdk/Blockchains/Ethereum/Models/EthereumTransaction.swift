//
//  EthereumTransaction.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 27.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift

public struct EthereumTransaction {
    public var nonce: BigUInt
    public var gasPrice: BigUInt = BigUInt(0)
    public var gasLimit: BigUInt = BigUInt(0)
    public var to: String
    public var value: BigUInt
    public var data: Data
    public var v: BigUInt = BigUInt(1)
    public var r: BigUInt = BigUInt(0)
    public var s: BigUInt = BigUInt(0)
    var chainID: BigUInt? = nil

    func hashForSignature(chainID: BigUInt? = nil) -> Data? {
        guard let encoded = self.encode(forSignature: true, chainID: chainID) else {return nil}
        let hash = encoded.sha3(.keccak256)
        return hash
    }

    func encode(forSignature: Bool, chainID: BigUInt? = nil) -> Data? {
        if (forSignature) {
            if chainID != nil  {
                let fields = [self.nonce, self.gasPrice, self.gasLimit, Data(hexString: to), self.value, self.data, chainID!, BigUInt(0), BigUInt(0)] as [AnyObject]
                return RLP.encode(fields)
            }
            else if self.chainID != nil  {
                let fields = [self.nonce, self.gasPrice, self.gasLimit, Data(hexString: to), self.value, self.data, self.chainID!, BigUInt(0), BigUInt(0)] as [AnyObject]
                return RLP.encode(fields)
            } else {
                let fields = [self.nonce, self.gasPrice, self.gasLimit, Data(hexString: to), self.value, self.data] as [AnyObject]
                return RLP.encode(fields)
            }
        } else {
            let encodeV = chainID == nil ? v : v - 27 + chainID! * 2 + 35

            let fields = [self.nonce, self.gasPrice, self.gasLimit, Data(hexString: to), self.value, self.data, encodeV, self.r, self.s] as [AnyObject]
            return RLP.encode(fields)
        }
    }
}
