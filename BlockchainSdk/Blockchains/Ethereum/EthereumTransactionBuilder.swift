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
import WalletCore

// Decoder: https://rawtxdecode.in
class EthereumTransactionBuilder {
    private let chainId: Int
    private let coinType: CoinType = .ethereum

    private var nonce: Int = -1

    init(chainId: Int) {
        self.chainId = chainId
    }

    func update(nonce: Int) {
        self.nonce = nonce
    }

    func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let preSigningOutput = try buildTxCompilerPreSigningOutput(input: input)
        return preSigningOutput.dataHash
    }

    func buildForSend(transaction: Transaction, signatureInfo: SignatureInfo) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let output = try buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    func buildDummyTransactionForL1(destination: String, value: String?, data: Data?, fee: Fee) throws -> Data {
        let valueData = BigUInt(Data(hex: value ?? "0x0"))
        switch fee.amount.type {
        case .coin:
            let input = try buildSigningInput(
                destination: .user(user: destination, value: valueData),
                fee: fee,
                parameters: EthereumTransactionParams(data: data)
            )
            return try buildTxCompilerPreSigningOutput(input: input).data

        case .token(let token):
            let input = try buildSigningInput(
                destination: .contract(user: destination, contract: token.contractAddress, value: valueData),
                fee: fee,
                parameters: EthereumTransactionParams(data: data)
            )

            return try buildTxCompilerPreSigningOutput(input: input).data
        case .reserve:
            throw BlockchainSdkError.notImplemented
        }
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

private extension EthereumTransactionBuilder {
    func buildTxCompilerPreSigningOutput(input: EthereumSigningInput) throws -> TxCompilerPreSigningOutput {
        let txInputData = try input.serializedData()
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            Log.debug("EthereumPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw EthereumTransactionBuilderError.walletCoreError(message: preSigningOutput.errorMessage)
        }

        return preSigningOutput
    }

    func buildSigningInput(transaction: Transaction) throws -> EthereumSigningInput {
        guard let amountValue = transaction.amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }

        switch transaction.amount.type {
        case .coin:
            return try buildSigningInput(
                destination: .user(user: transaction.destinationAddress, value: amountValue),
                fee: transaction.fee,
                parameters: transaction.params as? EthereumTransactionParams
            )
        case .token(let token):
            return try buildSigningInput(
                destination: .contract(
                    user: transaction.destinationAddress,
                    contract: transaction.contractAddress ?? token.contractAddress,
                    value: amountValue
                ),
                fee: transaction.fee,
                parameters: transaction.params as? EthereumTransactionParams
            )
        case .reserve:
            throw BlockchainSdkError.notImplemented
        }
    }

    func buildSigningInput(destination: DestinationType, fee: Fee, parameters: EthereumTransactionParams?) throws -> EthereumSigningInput {
        let nonceValue = BigUInt(parameters?.nonce ?? nonce)

        guard nonceValue >= 0 else {
            throw EthereumTransactionBuilderError.invalidNonce
        }

        let input = try EthereumSigningInput.with { input in
            input.chainID = BigUInt(chainId).serialize()
            input.nonce = nonceValue.serialize()

            // EIP-1559. https://eips.ethereum.org/EIPS/eip-1559
            if let feeParameters = fee.parameters as? EthereumEIP1559FeeParameters {
                input.txMode = .enveloped
                input.gasLimit = feeParameters.gasLimit.serialize()
                input.maxFeePerGas = feeParameters.baseFee.serialize()
                input.maxInclusionFeePerGas = feeParameters.priorityFee.serialize()
            } else {
                throw EthereumTransactionBuilderError.feeParametersNotFound
            }

            input.transaction = .with {
                switch destination {
                case .user(let user, let value):
                    input.toAddress = user
                    $0.transfer = .with {
                        $0.amount = value.serialize()
                        if let data = parameters?.data {
                            $0.data = data
                        }
                    }
                case .contract(let user, let contract, let value):
                    input.toAddress = contract
                    $0.erc20Transfer = .with {
                        $0.amount = value.serialize()
                        $0.to = user
                    }
                }
            }
        }

        return input
    }

    func buildSigningOutput(input: EthereumSigningInput, signatureInfo: SignatureInfo) throws -> EthereumSigningOutput {
        guard signatureInfo.signature.count == Constants.signatureSize else {
            throw EthereumTransactionBuilderError.invalidSignatureCount
        }

        let decompressed = try Secp256k1Key(with: signatureInfo.publicKey).decompress()
        let secp256k1Signature = try Secp256k1Signature(with: signatureInfo.signature)
        let unmarshal = try secp256k1Signature.unmarshal(with: decompressed, hash: signatureInfo.hash)
        let txInputData = try input.serializedData()

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

        let compileWithSignatures = TransactionCompiler.compileWithSignatures(
            coinType: coinType,
            txInputData: txInputData,
            signatures: signatures,
            publicKeys: publicKeys
        )

        let output = try EthereumSigningOutput(serializedData: compileWithSignatures)

        if output.error != .ok {
            Log.debug("EthereumSigningOutput has a error: \(output.errorMessage)")
            throw EthereumTransactionBuilderError.walletCoreError(message: output.errorMessage)
        }

        if output.encoded.isEmpty {
            throw EthereumTransactionBuilderError.transactionEncodingFailed
        }

        return output
    }
}

extension EthereumTransactionBuilder {
    enum DestinationType: Hashable {
        case user(user: String, value: BigUInt)
        case contract(user: String, contract: String, value: BigUInt)
    }

    private enum Constants {
        static let signatureSize = 64
    }
}

enum EthereumTransactionBuilderError: Error {
    case feeParametersNotFound
    case invalidSignatureCount
    case invalidAmount
    case invalidNonce
    case transactionEncodingFailed
    case walletCoreError(message: String)
}
