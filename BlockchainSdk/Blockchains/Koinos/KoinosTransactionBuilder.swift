//
//  KoinosTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 17.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class KoinosTransactionBuilder {
    private let isTestnet: Bool
    private let transferEntryPoint: UInt32 = 0x27f576ca
    private let transactionIdPrefix = "0x1220"
    
    private var contractId: String {
        if isTestnet {
            "1FaSvLjQJsCJKq5ybmGsMMQs8RQYyVv8ju"
        } else {
            "15DJN4a8SgrbGhhGksSBASiSYjGnMU8dGL"
        }
    }
    
    private var chainId: String {
        if isTestnet {
            "EiBncD4pKRIQWco_WRqo5Q-xnXR7JuO3PtZv983mKdKHSQ=="
        } else {
            "EiBZK_GGVP0H_fXVAM3j6EAuz3-B-l3ejxRSewi7qIBfSA=="
        }
    }
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
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
                $0.contractID = contractId.base58DecodedData
                $0.entryPoint = transferEntryPoint
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
        
        guard let chainID = chainId.base64URLDecodedData() else {
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
        let transactionId = "\(transactionIdPrefix)\(hashToSign.hexString.lowercased())"
        
        let transactionToSign = KoinosProtocol.Transaction(
            header: KoinosProtocol.TransactionHeader(
                chainId: chainId,
                rcLimit: manaLimitSatoshi,
                nonce: encodedNextNonce.base64UrlEncodedString(),
                operationMerkleRoot: operationMerkleRoot.base64UrlEncodedString(),
                payer: from,
                payee: nil
            ),
            id: transactionId,
            operations: [
                KoinosProtocol.Operation(
                    callContract: KoinosProtocol.CallContractOperation(
                        contractIdBase58: contractId,
                        entryPoint: Int(transferEntryPoint),
                        argsBase64: operation.callContract.args.base64UrlEncodedString()
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
                Data([0x20] + normalizedSignature.bytes).base64UrlEncodedString()
            ]
        )
    }
}

// MARK: Fileprivate extensions
private extension Data {
    func base64UrlEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}

private extension String {
    func base64URLToBase64() -> String {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
    
    /// Decodes a Base64 URL-safe encoded string to Data
    func base64URLDecodedData() -> Data? {
        let base64 = self.base64URLToBase64()
        return Data(base64Encoded: base64)
    }
}
