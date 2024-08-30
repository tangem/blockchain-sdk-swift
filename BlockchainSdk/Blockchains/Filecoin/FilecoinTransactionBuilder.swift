//
//  FilecoinTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 29.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk
import WalletCore

final class FilecoinTransactionBuilder {
    private let wallet: Wallet
    
    init(wallet: Wallet) {
        self.wallet = wallet
    }
    
    func buildForSign(transaction: Transaction, nonce: UInt64) throws -> Data {
        guard let feeParameters = transaction.fee.parameters as? FilecoinFeeParameters else {
            throw WalletError.failedToBuildTx
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
    ) throws -> FilecoinSignedTransactionBody {
        guard let feeParameters = transaction.fee.parameters as? FilecoinFeeParameters else {
            throw WalletError.failedToBuildTx
        }
        
        let signatures = DataVector()
        signatures.add(data: signatureInfo.signature)

        let publicKeys = DataVector()
        publicKeys.add(data: try Secp256k1Key(with: signatureInfo.publicKey).decompress())
        
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
            throw WalletError.failedToBuildTx
        }
        
        return try JSONDecoder().decode(FilecoinSignedTransactionBody.self, from: jsonData)
    }
    
    private func makeSigningInput(
        transaction: Transaction,
        nonce: UInt64,
        feeParameters: FilecoinFeeParameters
    ) throws -> FilecoinSigningInput {
        guard let value = transaction.amount.bigUIntValue else {
            throw WalletError.failedToBuildTx
        }
        
        return try FilecoinSigningInput.with { input in
            input.to = transaction.destinationAddress
            input.nonce = nonce
            
            input.value = value.serialize()
            
            input.gasFeeCap = feeParameters.gasUnitPrice.serialize()
            input.gasLimit = feeParameters.gasLimit
            input.gasPremium = feeParameters.gasPremium.serialize()
            
            input.publicKey = try Secp256k1Key(with: wallet.publicKey.blockchainKey).decompress()
        }
    }
}
