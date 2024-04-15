//
//  EthereumTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import TangemSdk

class EthereumTransactionBuilder {
    private let walletPublicKey: Data
    private let chainId: BigUInt
    
    init(walletPublicKey: Data, chainId: Int) throws {
        self.walletPublicKey = try Secp256k1Key(with: walletPublicKey).decompress()
        self.chainId = BigUInt(chainId)
    }
    
    public func buildForSign(transaction: Transaction, nonce: Int) -> CompiledEthereumTransaction? {
        guard let feeParameters = transaction.fee.parameters as? EthereumFeeParameters else {
            return nil
        }

        let parameters = transaction.params as? EthereumTransactionParams
        let nonceValue = BigUInt(parameters?.nonce ?? nonce)
        
        guard nonceValue >= 0 else {
            return nil
        }
        
        guard let amountValue = transaction.amount.bigUIntValue else {
            return nil
        }

        let data: Data? = {
            if let data = parameters?.data {
                return data
            }

            return try? buildForTokenTransfer(destination: transaction.destinationAddress, amount: transaction.amount)
        }()

        guard let data = data else {
            return nil
        }

        guard let targetAddress = transaction.amount.type == .coin ? transaction.destinationAddress: transaction.contractAddress else {
            return nil
        }

        let transaction = EthereumTransaction(
            nonce: nonceValue,
            gasPrice: feeParameters.gasPrice,
            gasLimit: feeParameters.gasLimit,
            to: targetAddress,
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
        
        let encodedBytesToSend = transaction.encode(forSignature: false, chainID: chainId)
        return encodedBytesToSend
    }

    // MARK: - Transaction data builder

    func buildForApprove(spender: String, amount: Decimal) -> Data {
        let bigUInt = EthereumUtils.mapToBigUInt(amount)
        return ApproveERC20TokenMethod(spender: spender, amount: bigUInt).data
    }

    func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        if !amount.type.isToken {
            return Data()
        }

        guard let bigUInt = amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }

        let method = TransferERC20TokenMethod(destination: destination, amount: bigUInt)
        return method.data
    }
}

enum EthereumTransactionBuilderError: Error {
    case invalidAmount
}
