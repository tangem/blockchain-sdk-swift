//
// SuiTransactionBuilder.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 30.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import TangemSdk


public class SuiTransactionBuilder {

    private var publicKey: Wallet.PublicKey
    private var coins: [SuiCoinObject] = []
    
    public init(publicKey: Wallet.PublicKey) {
        self.publicKey = publicKey
    }
    
    public func update(coins: [SuiCoinObject]) {
        self.coins = coins
    }
    
    
    public func buildForInspect(amount: Amount, destination: String, referenceGasPrice: Decimal) throws -> String {
        let signer = try WalletCoreAddressService(coin: .sui).makeAddress(for: publicKey, with: .default)

        let useCoins = coins
        let budget = coins.reduce(into: Decimal(0)) { partialResult, coin in
            partialResult += coin.balance
        }
        
        let input = WalletCore.SuiSigningInput.with { input in
            let inputCoins = useCoins.map { coin in
                SuiObjectRef.with({ coins in
                    coins.version = coin.version
                    coins.objectID = coin.coinObjectId
                    coins.objectDigest = coin.digest
                })
            }
            
            input.paySui = WalletCore.SuiPaySui.with({ pay in
                pay.inputCoins = inputCoins
                pay.recipients = [destination]
                pay.amounts = [amount.value.uint64Value]
            })
            
            input.signer = signer.value
            input.gasBudget = (budget - amount.value).uint64Value
            input.referenceGasPrice = referenceGasPrice.uint64Value
        }
        
        let signatureMock = Data(repeating: 0x01, count: 64)
        
        let compiled = try TransactionCompiler.compileWithSignatures(coinType: .sui,
                                                                     txInputData: input.serializedData(),
                                                                     signatures: signatureMock.asDataVector(),
                                                                     publicKeys: publicKey.blockchainKey.asDataVector())
        let output = try SuiSigningOutput(serializedData: compiled)
        
        return output.unsignedTx
    }
    
    
    public func buildForSign(transaction: Transaction) throws -> Data {
        let input = try input(amount: transaction.amount, destination: transaction.destinationAddress, fee: transaction.fee)
        
        let preImageHashes = try TransactionCompiler.preImageHashes(coinType: .sui, txInputData: input.serializedData())
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)
        
        if preSigningOutput.error != .ok {
            Log.debug("SuiPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }
        
        return preSigningOutput.dataHash
        
    }
    
    public func buildForSend(transaction: Transaction, signature: Data) throws -> (txBytes: String, signature: String) {
        let input = try input(amount: transaction.amount, destination: transaction.destinationAddress, fee: transaction.fee)
        
        let compiled = try TransactionCompiler.compileWithSignaturesAndPubKeyType(coinType: .sui,
                                                                                  txInputData: input.serializedData(),
                                                                                  signatures: signature.asDataVector(),
                                                                                  publicKeys: publicKey.blockchainKey.asDataVector(),
                                                                                  pubKeyType: .ed25519)
        
        let output = try SuiSigningOutput(serializedData: compiled)
        return (output.unsignedTx, output.signature)
    }
    
    private func input(amount: Amount, destination: String, fee: Fee) throws -> WalletCore.SuiSigningInput {
        let signer = try WalletCoreAddressService(coin: .sui).makeAddress(for: publicKey, with: .default)
        
        guard let suiFeeParameters = fee.parameters as? SuiFeeParameters else {
            throw WalletError.failedToBuildTx
        }
        
        let useCoins = getCoins(for: amount.value + suiFeeParameters.amount)

        return WalletCore.SuiSigningInput.with { input in
            let inputCoins = useCoins.map { coin in
                SuiObjectRef.with({ coins in
                    coins.version = coin.version
                    coins.objectID = coin.coinObjectId
                    coins.objectDigest = coin.digest
                })
            }
            
            input.paySui = WalletCore.SuiPaySui.with({ pay in
                pay.inputCoins = inputCoins
                
                pay.recipients = [destination]
                pay.amounts = [amount.value.uint64Value]
            })
            
            input.signer = signer.value
            input.gasBudget = suiFeeParameters.gasBudget.uint64Value
            input.referenceGasPrice = suiFeeParameters.gasPrice.uint64Value
        }
        
    }
    
    private func getCoins(for amount: Decimal) -> [SuiCoinObject] {
        var inputs: [SuiCoinObject] = []
        var total: Decimal = 0
        
        for coin in coins {
            inputs.append(coin)
            total += coin.balance
            
            if total >= amount {
                break
            }
        }
        
        return inputs
    }
    
}


public struct SuiCoinObject {
    
    public let coinType: String
    public let coinObjectId: String
    public let version: UInt64
    public let digest: String
    public let balance: Decimal
    
    public static func from(_ response: SuiGetCoins.Coin) -> Self? {
        guard let `version` = Decimal(stringValue: response.version)?.uint64Value,
              let `balance` = Decimal(stringValue: response.balance) else {
            return nil
        }
        
        return SuiCoinObject(coinType: response.coinType,
                             coinObjectId: response.coinObjectId,
                             version: version,
                             digest: response.digest,
                             balance: balance)
    }
    
}
