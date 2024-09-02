//
//  StakeKitTransactionSender.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 02.09.2024.
//

import Foundation

public protocol StakeKitTransactionSender {
    /// Return stream with tx which was sent one by one
    /// If catch error stream will be stopped
    func sendStakeKit(transactions: [StakeKitTransaction], signer: TransactionSigner) async throws -> AsyncThrowingStream<StakeKitTransactionSendResult, Error>
}

protocol StakeKitTransactionSenderProvider {
    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data
    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> Data
    func broadcast(rawTransaction: Data) throws -> TransactionSendResult
}

// MARK: - Common implementation for StakeKitTransactionSenderProvider

extension StakeKitTransactionSender where Self: StakeKitTransactionSenderProvider, Self: WalletProvider {
    func sendStakeKit(transactions: [StakeKitTransaction], signer: TransactionSigner) async throws -> AsyncThrowingStream<StakeKitTransactionSendResult, Error> {
        .init { continuation in
            let task = Task {
                do {
                    let preparedHashes = try transactions.map { try prepareDataForSign(transaction: $0) }
                    let signatures: [SignatureInfo] = try await signer.sign(hashes: preparedHashes, walletPublicKey: wallet.publicKey).async()

                    assert(transactions.count == signatures.count, "Signatures count don't equal to initial transactions count")

                    for (transaction, signature) in zip(transactions, signatures) {
                        try Task.checkCancellation()
                        let dataToSend = try prepareDataForSend(transaction: transaction, signature: signature)
                        let result = try await broadcast(rawTransaction: dataToSend)
                        continuation.yield(.init(transaction: transaction, result: result))

                        print("Start 5 sec ->> ")
                        try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
                    }

                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                    return
                }
            }

            continuation.onTermination = { termination in
                print("termination ->>", termination)

                switch termination {
                case .cancelled:
                    task.cancel()
                case .finished(let error as CancellationError):
                    task.cancel() // Check it
                case .finished(let error):
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}
