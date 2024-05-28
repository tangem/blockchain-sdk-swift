//
//  KoinosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 17.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum KoinosTransactionBuilderError: Error {
    case unableToParseParams
}

class KoinosTransactionBuilder {
    private let koinContractAbi: KoinContractAbi
    
    init(isTestnet: Bool) {
        self.koinContractAbi = KoinContractAbi(isTestnet: isTestnet)
    }
    
    func buildForSign(
        transaction: Transaction,
        currentNonce: KoinosAccountNonce
    ) throws -> (KoinosProtocol.Transaction, Data) {
        let from = transaction.sourceAddress
        let to = transaction.destinationAddress
        let amount = transaction.amount.value
        
        guard let params = transaction.params as? KoinosTransactionParams else {
            throw KoinosTransactionBuilderError.unableToParseParams
        }
        
        let satoshi = pow(10, Blockchain.koinos(testnet: false).decimalCount)
        let amountSatoshi = (amount * satoshi).roundedDecimalNumber.uint64Value
        
        let manaLimit = params.manaLimit
        let manaLimitSatoshi = (manaLimit * satoshi).roundedDecimalNumber.uint64Value
        
        let nextNonce = currentNonce.nonce + 1

        let operation = try Koinos_Protocol_operation.with {
            $0.callContract = try Koinos_Protocol_call_contract_operation.with {
                $0.contractID = koinContractAbi.contractID.base58DecodedData
                $0.entryPoint = KoinContractAbi.Transfer.entryPoint
                $0.args = try Koinos_Contracts_Token_transfer_arguments.with {
                    $0.from = from.base58DecodedData
                    $0.to = to.base58DecodedData
                    $0.value = amountSatoshi
                }
                .serializedData()
            }
        }
        
        let operationSha256 = try operation.serializedData().getSha256()
        let operationMerkleRoot = Data([18, 32] + operationSha256.bytes)
        let encodedNextNonce = try Koinos_Chain_value_type.with {
            $0.uint64Value = nextNonce
        }
        .serializedData()
        
        guard let chainID = koinContractAbi.chainID.base64URLDecodedData() else {
            throw WalletError.failedToBuildTx
        }
        
        let header = Koinos_Protocol_transaction_header.with {
            $0.chainID = chainID
            $0.rcLimit = manaLimitSatoshi
            $0.nonce = encodedNextNonce
            $0.operationMerkleRoot = operationMerkleRoot
            $0.payer = from.base58DecodedData
        }
        
        let hashToSign = try header.serializedData().getSha256()
        let transactionId = "\(KoinContractAbi.Transfer.transactionIDPrefix)\(hashToSign.hexString.lowercased())"
        
        let transactionToSign = KoinosProtocol.Transaction(
            header: KoinosProtocol.TransactionHeader(
                chainId: koinContractAbi.chainID,
                rcLimit: manaLimitSatoshi,
                nonce: encodedNextNonce.base64URLEncodedString(),
                operationMerkleRoot: operationMerkleRoot.base64URLEncodedString(),
                payer: from,
                payee: nil
            ),
            id: transactionId,
            operations: [
                KoinosProtocol.Operation(
                    callContract: KoinosProtocol.CallContractOperation(
                        contractIdBase58: koinContractAbi.contractID,
                        entryPoint: Int(KoinContractAbi.Transfer.entryPoint),
                        argsBase64: operation.callContract.args.base64URLEncodedString()
                    )
                )
            ],
            signatures: []
        )
        
        return (transactionToSign, hashToSign)
    }
    
    func buildForSend(transaction: KoinosProtocol.Transaction, normalizedSignature: Data) -> KoinosProtocol.Transaction  {
        KoinosProtocol.Transaction(
            header: transaction.header,
            id: transaction.id,
            operations: transaction.operations,
            signatures: [
                Data([0x20] + normalizedSignature.bytes).base64URLEncodedString()
            ]
        )
    }
}
