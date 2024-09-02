//
//  StakeKitTransactionSender.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 02.09.2024.
//

import Foundation
import TangemSdk

public protocol StakeKitTransactionSender {
    /// Return stream with tx which was sent one by one
    /// If catch error stream will be stopped
    /// In case when manager already implemented the `StakeKitTransactionSenderProvider` method will be not required
    func sendStakeKit(transactions: [StakeKitTransaction], signer: TransactionSigner, delay second: UInt64?) -> AsyncThrowingStream<StakeKitTransactionSendResult, Error>
}

protocol StakeKitTransactionSenderProvider {
    associatedtype RawTransaction

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data
    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction
    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String
}

// MARK: - Common implementation for StakeKitTransactionSenderProvider

extension StakeKitTransactionSender where Self: StakeKitTransactionSenderProvider, Self: WalletProvider, RawTransaction: CustomStringConvertible {
    func sendStakeKit(transactions: [StakeKitTransaction], signer: TransactionSigner, delay second: UInt64?) -> AsyncThrowingStream<StakeKitTransactionSendResult, Error> {
        .init { continuation in
            let task = Task {
                do {
                    let preparedHashes = try transactions.map { try prepareDataForSign(transaction: $0) }
                    let signatures: [SignatureInfo] = try await signer.sign(hashes: preparedHashes, walletPublicKey: wallet.publicKey).async()

                    assert(transactions.count == signatures.count, "Signatures count don't equal to initial transactions count")

                    for (transaction, signature) in zip(transactions, signatures) {
                        try Task.checkCancellation()
                        let rawTransaction = try prepareDataForSend(transaction: transaction, signature: signature)

                        do {
                            let result: TransactionSendResult = try await broadcast(transaction: transaction, rawTransaction: rawTransaction)
                            continuation.yield(.init(transaction: transaction, result: result))
                        } catch {
                            throw StakeKitTransactionSendError(transaction: transaction, error: error)
                        }

                        if transactions.count > 1, let second {
                            Log.log("\(self) start \(second) second delay between the transactions sending")
                            try await Task.sleep(nanoseconds: second * NSEC_PER_SEC)
                        }
                    }

                    continuation.finish()

                } catch {
                    Log.log("\(self) catch \(error) when sent staking transaction")
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { termination in
                switch termination {
                case .cancelled:
                    task.cancel()
                case .finished(let error):
                    task.cancel()
                case .finished(.none):
                    break
                }
            }
        }
    }

    /// Convenience method with adding the `PendingTransaction` to the wallet  and `SendTxError` mapping
    private func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> TransactionSendResult {
        do {
            let hash: String = try await broadcast(transaction: transaction, rawTransaction: rawTransaction)
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(
                stakeKitTransaction: transaction,
                source: wallet.defaultAddress.value,
                hash: hash
            )
            wallet.addPendingTransaction(record)
            return TransactionSendResult(hash: hash)
        } catch {
            throw SendTxErrorFactory().make(error: error, with: rawTransaction.description)
        }
    }
}
