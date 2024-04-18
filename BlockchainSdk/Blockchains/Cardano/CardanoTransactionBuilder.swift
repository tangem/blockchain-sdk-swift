//
//  CardanoTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 20.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import BigInt
import TangemSdk

// You can decode your CBOR transaction here: https://cbor.me
class CardanoTransactionBuilder {
    private var outputs: [CardanoUnspentOutput] = []
    private let coinType: CoinType = .cardano

    init() {}
}

extension CardanoTransactionBuilder {
    func update(outputs: [CardanoUnspentOutput]) {
        self.outputs = outputs
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            Log.debug("CardanoPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, signature: SignatureInfo) throws -> Data {
        let input = try buildCardanoSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()

        let signatures = DataVector()
        signatures.add(data: signature.signature)

        let publicKeys = DataVector()
        // WalletCore used here `.ed25519Cardano` curve with 128 bytes publicKey.
        // For more info see CardanoUtil
        let publicKey = signature.publicKey.trailingZeroPadding(toLength: CardanoUtil.extendedPublicKeyCount)
        publicKeys.add(data: publicKey)

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try CardanoSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            Log.debug("CardanoSigningOutput has a error: \(output.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        if output.encoded.isEmpty {
            throw WalletError.failedToBuildTx
        }

        return output.encoded
    }

    func getFee(amount: Amount, destination: String, source: String) throws -> Decimal {
        let inputAmountType = try inputAmountType(amount: amount, fee: .zeroCoin(for: .cardano(extended: false)))

        let input = try buildCardanoSigningInput(
            source: source,
            destination: destination,
            amount: inputAmountType
        )

        return Decimal(input.plan.fee)
    }

    /// - If the amount is Cardano  -> just `amount`
    /// - If the amount is a `token` and enough for the change then will return `minAdaValue`
    /// - If the amount is a `token` and not enough for the change then will return `balance - fee`
    func buildCardanoSpendingAdaValue(amount: Amount, fee: Amount) throws -> UInt64 {
        let uint64Amount = (amount.value * amount.decimalValue).roundedDecimalNumber.uint64Value

        switch amount.type {
        case .coin:
            return uint64Amount
        case .token(let token):
            let uint64Fee = (fee.value * fee.decimalValue).roundedDecimalNumber.uint64Value
            let spendingAdaValue = try buildMinAdaValueUInt64Amount(token: token, amount: uint64Amount, fee: uint64Fee)
            return spendingAdaValue
        case .reserve:
            throw BlockchainSdkError.notImplemented
        }
    }

    func minChange(exclude: Token?) throws -> UInt64 {
        let excludeAsset = try exclude.map { try self.asset(for: $0) }
        let assetsBalances = outputs
            .flatMap { $0.assets }
            .filter { $0 != excludeAsset }
            .reduce(into: [:]) { result, asset in
                result[asset, default: 0] += asset.amount
            }

        let tokenBundle = CardanoTokenBundle.with {
            $0.token = assetsBalances.map { asset, balance in
                buildCardanoTokenAmount(asset: asset, amount: BigUInt(balance))
            }
        }

        let minChange = try CardanoMinAdaAmount(tokenBundle: tokenBundle.serializedData())
        return minChange
    }
}

// MARK: - Private

extension CardanoTransactionBuilder {
    func buildMinAdaValueUInt64Amount(token: Token, amount: UInt64, fee: UInt64) throws -> UInt64 {
        let tokenBundle = try CardanoTokenBundle.with {
            $0.token = try [buildCardanoTokenAmount(asset: asset(for: token), amount: BigUInt(amount))]
        }
        let minAmount = try CardanoMinAdaAmount(tokenBundle: tokenBundle.serializedData())
        let balance = outputs.reduce(0, { $0 + $1.amount })
        let minChange = try minChange(exclude: token)
        let change = balance - minAmount

        // If wallet doesn't have enough balance for minimum change
        // Then spend all ADA
        if change > 0, change < minChange {
            let spendingAdaValue = balance - fee
            return spendingAdaValue
        }

        return minAmount
    }

    func asset(for token: Token) throws -> CardanoUnspentOutput.Asset {
        let asset = outputs
            .flatMap { $0.assets }
            .first { asset in
                // We should use this HACK here to find
                // right policyID and the hexadecimal asset name
                // Must be used exactly same as in utxo
                token.contractAddress.hasPrefix(asset.policyID)
            }

        guard let asset else {
            throw CardanoTransactionBuilderError.assetNotFound
        }

        return asset
    }

    func buildCardanoTokenAmount(asset: CardanoUnspentOutput.Asset, amount: BigUInt) -> CardanoTokenAmount {
        CardanoTokenAmount.with {
            $0.policyID = asset.policyID
            $0.assetNameHex = asset.assetNameHex
            // Should set amount as hex e.g. "01312d00" = 20000000
            $0.amount = amount.serialize()
        }
    }

    func inputAmountType(amount: Amount, fee: Amount) throws -> InputAmountType {
        let uint64AdaAmount = try buildCardanoSpendingAdaValue(amount: amount, fee: fee)

        switch amount.type {
        case .coin:
            return .ada(uint64AdaAmount)
        case .token(let token):
            let uint64TokenAmount = (amount.value * amount.decimalValue).roundedDecimalNumber.uint64Value
            return .token(token: token, amount: uint64TokenAmount, adaValue: uint64AdaAmount)
        case .reserve:
            throw BlockchainSdkError.notImplemented
        }
    }

    func buildCardanoSigningInput(transaction: Transaction) throws -> CardanoSigningInput {
        let amount = try inputAmountType(amount: transaction.amount, fee: transaction.fee.amount)

        return try buildCardanoSigningInput(
            source: transaction.sourceAddress,
            destination: transaction.destinationAddress,
            amount: amount
        )
    }

    func buildCardanoSigningInput(source: String, destination: String, amount: InputAmountType) throws -> CardanoSigningInput {
        print("buildCardanoSigningInput uint64Amount ->>", amount)

        var input = CardanoSigningInput.with {
            $0.transferMessage.toAddress = destination
            $0.transferMessage.changeAddress = source
            $0.transferMessage.useMaxAmount = false
            // Transaction validity time. Currently we are using absolute values.
            // At 16 April 2023 was 90007700 slot number.
            // We need to rework this logic to use relative validity time.
            // TODO: https://tangem.atlassian.net/browse/IOS-3471
            // This can be constructed using absolute ttl slot from `/metadata` endpoint.
            $0.ttl = 190000000
        }

        if outputs.isEmpty {
            throw CardanoError.noUnspents
        }

        input.utxos = outputs.map { output -> CardanoTxInput in
            CardanoTxInput.with {
                $0.outPoint.txHash = Data(hexString: output.transactionHash)
                $0.outPoint.outputIndex = output.outputIndex
                $0.address = output.address
                $0.amount = output.amount
                
                if !output.assets.isEmpty {
                    $0.tokenAmount = output.assets.map { asset in
                        CardanoTokenAmount.with {
                            $0.policyID = asset.policyID
                            $0.assetNameHex = asset.assetNameHex
                            // Amount in hexadecimal e.g. 2dc6c0 = 3000000
                            $0.amount = BigInt(asset.amount).serialize()
                        }
                    }
                }
            }
        }

        switch amount {
        case .ada(let uInt64):
            // For coin just set amount which will be sent
            input.transferMessage.amount = uInt64
        case .token(let token, let uInt64, let adaValue):
            let tokenBundle = try CardanoTokenBundle.with {
                let asset = try asset(for: token)
                $0.token = [buildCardanoTokenAmount(asset: asset, amount: BigUInt(uInt64))]
            }

            // We have to set the minAmount because the utxo amount mustn't be empty
            input.transferMessage.amount = adaValue
            input.transferMessage.tokenAmount = tokenBundle
        }

        input.plan = AnySigner.plan(input: input, coin: coinType)

//        let change = input.plan.change
//        if change > 0, change < Constants.dust {
//            throw CardanoError.lowAda
//        }

        if input.plan.error != .ok {
            Log.debug("CardanoSigningInput has a error: \(input.plan.error)")
            throw WalletError.failedToBuildTx
        }

        return input
    }
}

extension CardanoTransactionBuilder {
    enum InputAmountType {
        case ada(UInt64)
        case token(token: Token, amount: UInt64, adaValue: UInt64)
    }

    private enum Constants {
        /// Min change is 1 ADA. It's also a dust value.
        static let dust: UInt64 = 1_000_000
    }
}

enum CardanoTransactionBuilderError: Error {
    case assetNotFound
}
