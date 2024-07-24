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
import IcpKit

final class ICPWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkService.host }
    
    var allowsFeeSelection: Bool = false
    
    // MARK: - Private Properties
    
    private let txBuilder: ICPTransactionBuilder
    private let networkService: ICPNetworkService
    
    private var signingOutput: ICPSigningOutput?
    
    // MARK: - Init
    
    init(wallet: Wallet, networkService: ICPNetworkService) {
        self.txBuilder = .init(decimalValue: wallet.blockchain.decimalValue)
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
            .withWeakCaptureOf(self)
            .flatMap { walletManager, input in
                walletManager.signTransaction(input: input, with: signer)
                    .withWeakCaptureOf(self)
                    .tryMap { walletManager, output in
                        try walletManager.txBuilder.buildForSend(output: output.callEnvelope)
                    }
                    .withWeakCaptureOf(self)
                    .flatMap { walletManager, signedTransaction in
                        walletManager.sendSigned(data: signedTransaction)
                            .handleEvents(receiveOutput: { [weak self] transactionSendResult in
                                let mapper = PendingTransactionRecordMapper()
                                let record = mapper.mapToPendingTransactionRecord(
                                    transaction: transaction,
                                    hash: transactionSendResult.hash
                                )
                                self?.signingOutput = nil
                                self?.wallet.addPendingTransaction(record)
                            })
                    }
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

    func signTransaction(
        input: ICPSigningInput,
        with signer: TransactionSigner
    ) -> AnyPublisher<ICPSigningOutput, Error> {
        let icpSigner = ICPSigner(signer: signer, walletPublicKey: wallet.publicKey)
        return icpSigner.sign(input: input)
            .handleEvents(receiveOutput: { [weak self] output in
                // save output for tracking transaction status
                self?.signingOutput = output
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private implementation
    
    private func sendSigned(data: Data) -> AnyPublisher<TransactionSendResult, Error> {
        networkService
            .send(data: data)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, _ in
                walletManager.trackStransactionStatus()
            }
            .map { _ in TransactionSendResult(hash: "") }
            .mapSendError(tx: data.hexString.lowercased())
            .eraseToAnyPublisher()
    }
    
    /// Tracks transaction status
    /// - Returns: Publisher for for the latest block index
    private func trackStransactionStatus() -> AnyPublisher<UInt64, Error>  {
        guard let signingOutput,
              let signedRequest = try? txBuilder.buildForSend(output: signingOutput.readStateEnvelope) else {
            return .anyFail(error: WalletError.empty)
        }
        
        return networkService.readState(data: signedRequest, paths: signingOutput.readStateTreePaths)
    }
    
}

private extension ICPWalletManager {
    enum Constants {
        static let fee = Decimal(stringValue: "0.0001")!
    }
}
