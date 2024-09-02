//
//  FilecoinTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 29.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import TangemSdk
import WalletCore

enum FilecoinTransactionBuilderError: Error {
    case filecoinFeeParametersNotFound
    case failedToConvertAmountToBigUInt
    case failedToGetDataFromJSON
}

final class FilecoinTransactionBuilder {
    private let publicKey: Wallet.PublicKey
    
    init(publicKey: Wallet.PublicKey) {
        self.publicKey = publicKey
    }
    
    func buildForSign(transaction: Transaction, nonce: UInt64) throws -> Data {
        guard let feeParameters = transaction.fee.parameters as? FilecoinFeeParameters else {
            throw FilecoinTransactionBuilderError.filecoinFeeParametersNotFound
        }
        
        let input = try makeSigningInput(transaction: transaction, nonce: nonce, feeParameters: feeParameters)
        let txInputData = try input.serializedData()
        
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: .filecoin, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)
        
        return preSigningOutput.dataHash
    }
    
    func buildForSend(
        transaction: Transaction,
        nonce: UInt64,
        signatureInfo: SignatureInfo
    ) throws -> FilecoinSignedMessage {
        guard let feeParameters = transaction.fee.parameters as? FilecoinFeeParameters else {
            throw FilecoinTransactionBuilderError.filecoinFeeParametersNotFound
        }
        
        let decompressed = try Secp256k1Key(with: signatureInfo.publicKey).decompress()
        let secp256k1Signature = try Secp256k1Signature(with: signatureInfo.signature)
        let unmarshal = try secp256k1Signature.unmarshal(with: decompressed, hash: signatureInfo.hash)

        // As we use the chainID in the transaction according to EIP-155
        // WalletCore will use formula to calculate `V`.
        // v = CHAIN_ID * 2 + 35
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md

        // It's strange but we can't use `unmarshal.v` here because WalletCore throw a error.
        // And we have to add one zero byte to the signature because
        // WalletCore has a validation on the signature count.
        // // https://github.com/tangem/wallet-core/blob/996bd5ab37f27e7f6e240a4ec9d0788dfb124e89/src/PublicKey.h#L35
        let v = BigUInt(unmarshal.v) - 27
        let encodedV = v == .zero ? Data([UInt8.zero]) : v.serialize()
        let signature = unmarshal.r + unmarshal.s + encodedV

        let signatures = DataVector()
        signatures.add(data: signature)

        let publicKeys = DataVector()
        publicKeys.add(data: decompressed)
        
        let input = try makeSigningInput(transaction: transaction, nonce: nonce, feeParameters: feeParameters)
        let txInputData = try input.serializedData()
        
        let compiledWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: .filecoin,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )
        
        let signingOutput = try FilecoinSigningOutput(serializedData: compiledWithSignatures)
                
        guard let jsonData = signingOutput.json.data(using: .utf8) else {
            throw FilecoinTransactionBuilderError.failedToGetDataFromJSON
        }
        
        return try JSONDecoder().decode(FilecoinSignedMessage.self, from: jsonData)
    }
    
    private func makeSigningInput(
        transaction: Transaction,
        nonce: UInt64,
        feeParameters: FilecoinFeeParameters
    ) throws -> FilecoinSigningInput {
        guard let value = transaction.amount.bigUIntValue else {
            throw FilecoinTransactionBuilderError.failedToConvertAmountToBigUInt
        }
        
        return try FilecoinSigningInput.with { input in
            input.to = transaction.destinationAddress
            input.nonce = nonce
            
            input.value = value.serialize()
            
            input.gasLimit = feeParameters.gasLimit
            input.gasFeeCap = feeParameters.gasFeeCap.serialize()
            input.gasPremium = feeParameters.gasPremium.serialize()
            
            input.publicKey = try Secp256k1Key(with: publicKey.blockchainKey).decompress()
        }
    }
}
