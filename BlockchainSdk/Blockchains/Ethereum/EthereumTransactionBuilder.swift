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

    init(chainId: Int?) throws {
        guard let chainId else {
            throw EthereumTransactionBuilderError.chainIdNotFount
        }

        self.chainId = chainId
    }

    public func update(nonce: Int) {
        self.nonce = nonce
    }

    public func buildForSign(transaction: Transaction) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let txInputData = try input.serializedData()
        let preImageHashes = TransactionCompiler.preImageHashes(coinType: coinType, txInputData: txInputData)
        let preSigningOutput = try TxCompilerPreSigningOutput(serializedData: preImageHashes)

        if preSigningOutput.error != .ok {
            Log.debug("EthereumPreSigningOutput has a error: \(preSigningOutput.errorMessage)")
            throw WalletError.failedToBuildTx
        }

        return preSigningOutput.dataHash
    }

    public func buildForSend(transaction: Transaction, signatureInfo: SignatureInfo) throws -> Data {
        let input = try buildSigningInput(transaction: transaction)
        let output = try buildSigningOutput(input: input, signatureInfo: signatureInfo)
        return output.encoded
    }

    public func buildForL1(destination: String, value: String?, data: Data?, fee: Fee) throws -> Data {
        let valueData = Data(hex: value ?? "0x0")
        let input = try buildSigningInput(
            amountValue: BigUInt(valueData),
            amountType: fee.amount.type,
            fee: fee,
            destination: destination,
            parameters: EthereumTransactionParams(data: data)
        )

        // Dummy data from the public documentation:
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
        let signature = Data(hex: "28ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa63627667cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83")
        let hash = Data(hex: "daf5a779ae972f972197303d7b574746c7ef83eadac0f2791ad23db92e4c8e53")
        let publicKey = Data(hex: "044bc2a31265153f07e70e0bab08724e6b85e217f8cd628ceb62974247bb493382ce28cab79ad7119ee1ad3ebcdb98a16805211530ecc6cfefa1b88e6dff99232a")
        let output = try buildSigningOutput(
            input: input,
            signatureInfo: .init(signature: signature, publicKey: publicKey, hash: hash)
        )

        return output.encoded
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
    func buildSigningInput(transaction: Transaction) throws -> EthereumSigningInput {
        guard let amountValue = transaction.amount.bigUIntValue else {
            throw EthereumTransactionBuilderError.invalidAmount
        }

        return try buildSigningInput(
            amountValue: amountValue,
            amountType: transaction.amount.type,
            fee: transaction.fee,
            destination: transaction.destinationAddress,
            parameters: transaction.params as? EthereumTransactionParams
        )
    }

    func buildSigningInput(
        amountValue: BigUInt,
        amountType: Amount.AmountType,
        fee: Fee,
        destination: String,
        parameters: EthereumTransactionParams?
    ) throws -> EthereumSigningInput {
        let nonceValue = BigUInt(parameters?.nonce ?? nonce)

        guard nonceValue >= 0 else {
            throw EthereumTransactionBuilderError.invalidNonce
        }

        let input = try EthereumSigningInput.with { input in
            input.chainID = BigUInt(chainId).serialize()
            input.nonce = nonceValue.serialize()

            // Legacy
            if let feeParameters = fee.parameters as? EthereumFeeParameters {
                input.txMode = .legacy
                input.gasLimit = feeParameters.gasLimit.serialize()
                input.gasPrice = feeParameters.gasPrice.serialize()
            }
            // EIP-1559. https://eips.ethereum.org/EIPS/eip-1559
            else if let feeParameters = fee.parameters as? EthereumEIP1559FeeParameters {
                input.txMode = .enveloped
                input.gasLimit = feeParameters.gasLimit.serialize()
                input.maxFeePerGas = feeParameters.baseFee.serialize()
                input.maxInclusionFeePerGas = feeParameters.priorityFee.serialize()
            } else {
                throw EthereumTransactionBuilderError.feeParametersNotFound
            }

            input.transaction = .with {
                switch amountType {
                case .coin:
                    input.toAddress = destination
                    $0.transfer = .with {
                        $0.amount = amountValue.serialize()
                        if let data = parameters?.data {
                            $0.data = data
                        }
                    }
                case .token(let value):
                    input.toAddress = value.contractAddress
                    $0.erc20Transfer = .with {
                        $0.amount = amountValue.serialize()
                        $0.to = destination
                    }
                case .reserve:
                    fatalError()
                }
            }
        }

        return input
    }

    func buildSigningOutput(input: EthereumSigningInput, signatureInfo: SignatureInfo) throws -> EthereumSigningOutput {
        guard signatureInfo.signature.count == Constants.signatureCount else {
            throw EthereumTransactionBuilderError.invalidSignatureCount
        }

        let unmarshal = try Secp256k1Signature(with: signatureInfo.signature)
            .unmarshal(with: signatureInfo.publicKey, hash: signatureInfo.hash)
        let txInputData = try input.serializedData()

        // As we use the chainID in the transaction according to EIP-155
        //  WalletCore will use formula to calculate `V`.
        // v = CHAIN_ID * 2 + 35
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md

        // It's strange but we can't use `unmarshal.v` here because WalletCore throw a error.
        // And we have to add one zero byte to the signature because
        // WalletCore has a validation on the signature count.
        // // https://github.com/tangem/wallet-core/blob/996bd5ab37f27e7f6e240a4ec9d0788dfb124e89/src/PublicKey.h#L35
        let signature = unmarshal.r + unmarshal.s + Data([UInt8.zero])

        let signatures = DataVector()
        signatures.add(data: signature)

        // Basically the publicKey will not use inside WalletCore
        // But anyway we add it for the data consistency
        let publicKeys = DataVector()
        publicKeys.add(data: signatureInfo.publicKey)

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
    private enum Constants {
        static let signatureCount = 64
    }
}

enum EthereumTransactionBuilderError: Error {
    case feeParametersNotFound
    case chainIdNotFount
    case invalidSignatureCount
    case invalidAmount
    case invalidNonce
    case transactionEncodingFailed
    case walletCoreError(message: String)
}
