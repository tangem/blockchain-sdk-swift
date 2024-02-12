//
//  HederaTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Hedera
import CryptoSwift
import TangemSdk

final class HederaTransactionBuilder {
    private let wallet: Wallet

    private lazy var client: Client = {
        return wallet.blockchain.isTestnet ? Client.forTestnet() : Client.forMainnet()
    }()

    private var curve: EllipticCurve { wallet.blockchain.curve }

    init(wallet: Wallet) {
        self.wallet = wallet
    }

    func buildForSign(transaction: Transaction) throws -> CompiledTransaction {
        let transactionValue = transaction.amount.value * pow(Decimal(10), transaction.amount.decimals)
        let transactionRoundedValue = transactionValue.rounded(roundingMode: .down)
        let transactionAmount = try Hbar(transactionRoundedValue, .tinybar)

        let feeValue = transaction.fee.amount.value * pow(Decimal(10), transaction.fee.amount.decimals)
        let feeRoundedValue = feeValue.rounded(roundingMode: .up)
        let feeAmount = try Hbar(feeRoundedValue, .tinybar)

        let sourceAccountId = try AccountId(parsing: transaction.sourceAddress)
        let destinationAccountId = try AccountId(parsing: transaction.destinationAddress)
        let transactionId = TransactionId.generateFrom(sourceAccountId)
        let transactionParams = transaction.params as? HederaTransactionParams

        let transferTransaction = try TransferTransaction()
            .hbarTransfer(sourceAccountId, transactionAmount.negated())
            .hbarTransfer(destinationAccountId, transactionAmount)
            .transactionId(transactionId)
            .maxTransactionFee(feeAmount)
            .transactionMemo(transactionParams?.memo ?? "")
            .freezeWith(client)

        /// Capturing an existing `Hedera.Client` instance here is not required but may come in handy
        /// because the client may already have some useful internal state at this point
        /// (like the list of ready-to-use GRCP nodes with health checks already performed)
        return CompiledTransaction(curve: curve, client: client, innerTransaction: transferTransaction)
    }

    func buildForSend(transaction: CompiledTransaction, signatures: [Data]) throws -> CompiledTransaction {
        let publicKey = try getPublicKey()
        let signatures = try normalizeSignatures(signatures)
        transaction.addSignatures(publicKey, signatures)

        return transaction
    }

    private func getPublicKey() throws -> Hedera.PublicKey {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return try .fromBytesEd25519(wallet.publicKey.blockchainKey)
        case .secp256k1:
            let ecdsaKey = try Secp256k1Key(with: wallet.publicKey.blockchainKey).compress()
            return try .fromBytesEcdsa(ecdsaKey)
        default:
            throw HederaError.unsupportedCurve(curveName: curve.rawValue)
        }
    }

    private func normalizeSignatures(_ signatures: [Data]) throws -> [Data] {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return signatures
        case .secp256k1:
            return try signatures
                .map { try Secp256k1Signature(with: $0) }
                .map { try $0.normalize() }
        default:
            throw HederaError.unsupportedCurve(curveName: curve.rawValue)
        }
    }
}

// MARK: - Auxiliary types

extension HederaTransactionBuilder {
    /// Auxiliary type that hides all implementation details (including dependency on `Hedera iOS SDK`).
    struct CompiledTransaction {
        private let curve: EllipticCurve
        private let client: Hedera.Client
        private let innerTransaction: Hedera.Transaction

        fileprivate init(
            curve: EllipticCurve,
            client: Hedera.Client,
            innerTransaction: Hedera.Transaction
        ) {
            self.curve = curve
            self.client = client
            self.innerTransaction = innerTransaction
        }

        func hashesToSign() throws -> [Data] {
            let hashes = try innerTransaction.signedTransactionsData()
            switch curve {
            case .ed25519, .ed25519_slip0010:
                return hashes
            case .secp256k1:
                return hashes.map { $0.sha3(.keccak256) }
            default:
                throw HederaError.unsupportedCurve(curveName: curve.rawValue)
            }
        }

        func addSignatures(_ publicKey: PublicKey, _ signatures: [Data]) {
            innerTransaction.addSignatures(publicKey, signatures)
        }

        func sendAndGetHash() async throws -> String {
            return try await innerTransaction
                .execute(client)
                .transactionId
                .toString()
        }
    }
}
