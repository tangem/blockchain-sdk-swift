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
    private let publicKey: Data
    private let chainId: Int
    private let coinType: CoinType = .ethereum

    private var nonce: Int = -1

    init(walletPublicKey: Data, chainId: Int?) throws {
        guard let chainId else {
            throw EthereumTransactionBuilderError.chainIdNotFount
        }

        self.publicKey = try Secp256k1Key(with: walletPublicKey).decompress()
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
        let txInputData = try input.serializedData()
        var signature = signatureInfo.signature

        guard signature.count == Constants.signatureCount else {
            throw EthereumTransactionBuilderError.invalidSignature
        }

        let secp256k1Signature = try Secp256k1Signature(with: signature)
        let unmarshal = try secp256k1Signature.unmarshal(with: signatureInfo.publicKey, hash: signatureInfo.hash)

        let zeroByte = Data([UInt8.zero])
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
        // Because we use chainID in the transaction walletCore will use formula to calculate fee
        //
        // But WalletCore has check on secp256k1 signature validation as 65 bytes count
        // https://github.com/tangem/wallet-core/blob/996bd5ab37f27e7f6e240a4ec9d0788dfb124e89/src/PublicKey.h#L35
// 28ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa63627667cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d8300
        signature += zeroByte // One zero byte

        let signatures = DataVector()
        signatures.add(data: unmarshal.r + unmarshal.s + zeroByte)

        print("signature ->>", signature.hexString)
        print("unmarshal ->>", unmarshal.data.hexString)

        let publicKeys = DataVector()
        publicKeys.add(data: publicKey)

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
            throw WalletError.failedToBuildTx
        }

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

        let parameters = transaction.params as? EthereumTransactionParams
        let nonceValue = BigUInt(parameters?.nonce ?? nonce)

        guard nonceValue >= 0 else {
            throw EthereumTransactionBuilderError.invalidNonce
        }

        let input = try EthereumSigningInput.with { input in
            input.chainID = BigUInt(chainId).serialize()
            input.nonce = nonceValue.serialize()

            // Legacy
            if let feeParameters = transaction.fee.parameters as? EthereumFeeParameters {
                input.txMode = .legacy
                input.gasLimit = feeParameters.gasLimit.serialize()
                input.gasPrice = feeParameters.gasPrice.serialize()
            }
            // EIP-1559. https://eips.ethereum.org/EIPS/eip-1559
            else if let feeParameters = transaction.fee.parameters as? EthereumEIP1559FeeParameters {
                input.txMode = .enveloped
                input.gasLimit = feeParameters.gasLimit.serialize()
                input.maxFeePerGas = feeParameters.baseFee.serialize()
                input.maxInclusionFeePerGas = feeParameters.priorityFee.serialize()
            } else {
                throw EthereumTransactionBuilderError.feeParametersNotFound
            }

            input.transaction = .with {
                switch transaction.amount.type {
                case .coin:
                    input.toAddress = transaction.destinationAddress
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
                        $0.to = transaction.destinationAddress
                    }
                case .reserve:
                    fatalError()
                }
            }
        }

        return input
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
    case invalidSignature
    case invalidAmount
    case invalidNonce
    case walletCoreError(message: String)
}
