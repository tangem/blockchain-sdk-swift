//
//  ICPWalletManager.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import Combine
import TangemSdk

final class ICPWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkService.host }
    
    var allowsFeeSelection: Bool = false
    
    // MARK: - Private Properties
    
    private let txBuilder: ICPTransactionBuilder
    private let networkService: ICPNetworkService
        
    // MARK: - Init
    
    init(wallet: Wallet, networkService: ICPNetworkService) {
        self.txBuilder = .init(
            decimalValue: wallet.blockchain.decimalValue,
            publicKey: wallet.publicKey.blockchainKey,
            nonce: try CryptoUtils.icpNonce()
        )
        self.networkService = networkService
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkService.getBalance(address: wallet.address)
            .sink(
                receiveCompletion: { [weak self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        self?.wallet.clearAmounts()
                        self?.wallet.clearPendingTransaction()
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] balance in
                    self?.updateWallet(with: balance)
                    completion(.success(()))
                }
            )
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        .justWithError(output: [Fee(Amount(with: wallet.blockchain, value: Constants.fee))])
    }
    
    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { [txBuilder] _ in
                try txBuilder.buildForSign(transaction: transaction)
            }
            .flatMap { [wallet, txBuilder] input in
                signer.sign(hashes: input.hashes(), walletPublicKey: wallet.publicKey)
                    .tryMap { signedHashes in
                        try txBuilder.buildForSend(
                            signedHashes: signedHashes,
                            input: input
                        )
                    }
            }
            .withWeakCaptureOf(self)
            .flatMap { walletManager, signingOutput in
                walletManager.send(
                    signingOutput: signingOutput,
                    transaction: transaction
                )
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private implementation
    
    private func updateWallet(with balance: Decimal) {
        // Reset pending transaction
        if balance != wallet.amounts[.coin]?.value {
            wallet.clearPendingTransaction()
        }
        
        wallet.add(coinValue: balance)
    }
    
    // MARK: - Private implementation
    
    private func send(
        signingOutput: ICPTransactionBuilder.ICPSigningOutput,
        transaction: Transaction
    ) -> AnyPublisher<TransactionSendResult, Error> {
        networkService
            .send(data: signingOutput.callEnvelope)
            .flatMap { [networkService] in
                networkService.readState(
                    data: signingOutput.readStateEnvelope,
                    paths: signingOutput.readStateTreePaths
                )
            }
            .map { blockIndex in TransactionSendResult(hash: String(blockIndex)) }
            .mapSendError(tx: signingOutput.callEnvelope.hexString.lowercased())
            .handleEvents(receiveOutput: { [weak self] transactionSendResult in
                guard let self else { return }
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(
                    transaction: transaction,
                    hash: transactionSendResult.hash
                )
                wallet.addPendingTransaction(record)
            })
            .eraseToAnyPublisher()
    }
}

private extension ICPWalletManager {
    enum Constants {
        static let fee = Decimal(stringValue: "0.0001")!
    }
}
