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
    private let publicKey: Data
    private let curve: EllipticCurve
    private let isTestnet: Bool

    private lazy var client: Client = {
        return isTestnet ? Client.forTestnet() : Client.forMainnet()
    }()

    init(publicKey: Data, curve: EllipticCurve, isTestnet: Bool) {
        self.publicKey = publicKey
        self.curve = curve
        self.isTestnet = isTestnet
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
            .prepareForUnitTestsIfNeeded(transactionParams: transaction.params, sourceAccountId: sourceAccountId)
            .freezeWith(client)

        logTransferTransaction(transferTransaction)

        /// Capturing an existing `Hedera.Client` instance here is not required but may come in handy
        /// because the client may already have some useful internal state at this point
        /// (like the list of ready-to-use GRCP nodes with health checks already performed)
        return CompiledTransaction(curve: curve, client: client, innerTransaction: transferTransaction)
    }

    func buildForSend(transaction: CompiledTransaction, signatures: [Data]) throws -> CompiledTransaction {
        let publicKey = try getPublicKey()
        transaction.addSignatures(publicKey, signatures)

        return transaction
    }

    private func getPublicKey() throws -> Hedera.PublicKey {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return try .fromBytesEd25519(publicKey)
        case .secp256k1:
            let ecdsaKey = try Secp256k1Key(with: publicKey).compress()
            return try .fromBytesEcdsa(ecdsaKey)
        default:
            throw HederaError.unsupportedCurve(curveName: curve.rawValue)
        }
    }

    private func logTransferTransaction(_ transaction: TransferTransaction) {
        let nodeAccountIds = transaction.nodeAccountIds?.toSet() ?? []
        let transactionId = transaction.transactionId?.toString() ?? "unknown"
        let networkNodes = client.network.filter { nodeAccountIds.contains($0.value) }
        Log.debug("\(#fileID): Constructed tx '\(transactionId)' with the following network nodes: \(networkNodes)")
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
            let dataToSign = try innerTransaction.signedTransactionsData()
            switch curve {
            case .ed25519, .ed25519_slip0010:
                // When using EdDSA, the original transaction is signed, not its hashes or something else
                return dataToSign
            case .secp256k1:
                return dataToSign.map { $0.sha3(.keccak256) }
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

// MARK: - Unit tests support

extension HederaTransactionBuilder.CompiledTransaction {
    /// - Note: For use in unit tests only.
    func toBytes() throws -> Data {
        return try innerTransaction.toBytes()
    }
}

private extension Hedera.Transaction {
    /// - Note: For use in unit tests only.
    @discardableResult
    func prepareForUnitTestsIfNeeded(transactionParams: TransactionParams?, sourceAccountId: AccountId) -> Self {
        guard let transactionParams = transactionParams as? HederaUnitTestsTransactionParams else {
            return self
        }

        return self
            .transactionMemo(transactionParams.memo)
            .nodeAccountIds(transactionParams.nodeAccountIds)
            .transactionId(.withValidStart(sourceAccountId, transactionParams.txValidStart))
    }
}
