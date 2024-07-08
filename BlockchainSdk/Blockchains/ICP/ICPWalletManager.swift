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
import TangemSdk

final class ICPWalletManager: BaseManager, WalletManager {
    var currentHost: String { networkService.host }
    
    var allowsFeeSelection: Bool = false
    
    // MARK: - Private Properties
    
    private let txBuilder: ICPTransactionBuilder
    private let networkService: ICPNetworkService
    private var signingOutput: ICPSigningOutput?
    
    // MARK: - Init
    
    init(wallet: Wallet, networkService: ICPNetworkService) {
        self.txBuilder = ICPTransactionBuilder(wallet: wallet)
        self.networkService = networkService
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        guard let balanceRequestData = try? makeBalanceRequestData() else {
            completion(.failure(WalletError.empty))
            return
        }
        cancellable = networkService.getBalance(data: balanceRequestData)
            .sink(
                receiveCompletion: { [weak self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        self?.wallet.clearAmounts()
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] balance in
                    self?.wallet.add(coinValue: balance)
                    completion(.success(()))
                }
            )
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        .justWithError(output: [Fee(Amount(with: wallet.blockchain,value: Constants.fee))])
    }
    
    func buildTransaction(
        input: ICPSigningInput,
        with signer: TransactionSigner
    ) -> AnyPublisher<ICPSigningOutput, Error> {
        let icpSigner = ICPSinger(signer: signer, walletPublicKey: wallet.publicKey)
        return icpSigner.sign(input: input)
            .handleEvents(receiveOutput: { [weak self] output in
                // save output for tracking transaction status
                self?.signingOutput = output
            })
            .eraseToAnyPublisher()
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
                walletManager.buildTransaction(input: input, with: signer)
                    .withWeakCaptureOf(self)
                    .tryMap { walletManager, output in
                        try walletManager.txBuilder.buildForSend(output: output.callEnvelope)
                    }
                    .withWeakCaptureOf(self)
                    .flatMap { walletManager, signedTransaction in
                        walletManager.sendSigned(data: signedTransaction)
                    }
            }
            .eraseSendError()
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
    
    private func trackStransactionStatus(attempt: Int = 0) -> AnyPublisher<UInt64, Error>  {
        guard let signingOutput,
              let signedRequest = try? txBuilder.buildForSend(output: signingOutput.readStateEnvelope) else {
            return .anyFail(error: WalletError.empty)
        }
                
        return networkService.readState(data: signedRequest, paths: signingOutput.readStateTreePaths)
            .delay(for: .milliseconds(Constants.readStateRetryDelayMilliseconds), scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .tryMap { walletManager, value in
                guard let value else {
                    throw WalletError.empty
                }
                return value
            }
            .retry(Constants.readStateRetryCount)
            .handleEvents(receiveOutput: { [weak self] value in
                self?.signingOutput = nil
            })
            .eraseToAnyPublisher()
    }
    
    private func makeBalanceRequestData() throws -> Data {
        let envelope = ICPRequestEnvelope(
            content: ICPRequestBuilder.makeCallRequestContent(
                method: .balance(account: Data(hex: wallet.address)),
                requestType: .query,
                nonce: try CryptoUtils.icpNonce()
            )
        )
        return try envelope.cborEncoded()
    }
}

extension ICPWalletManager {
    enum Constants {
        static let fee = Decimal(stringValue: "0.0001")!
        static let readStateRetryCount = 3
        static let readStateRetryDelayMilliseconds = 500
    }
}

extension CryptoUtils {
    static func icpNonce() throws -> Data {
        try generateRandomBytes(count: 32)
    }
}
