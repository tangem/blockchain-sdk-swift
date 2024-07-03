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
import PotentCBOR

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
        cancellable = networkService.getInfo(address: wallet.address)
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
    }
    
    func buildTransactionOld(input: InternetComputerSigningInput, with signer: TransactionSigner? = nil) throws -> InternetComputerSigningOutput {
        let output: InternetComputerSigningOutput
        
        if let signer {
            guard let publicKey = PublicKey(tangemPublicKey: self.wallet.publicKey.blockchainKey, publicKeyType: CoinType.internetComputer.publicKeyType) else {
                throw WalletError.failedToBuildTx
            }
            
            
            
            let coreSigner = WalletCoreSigner(
                sdkSigner: signer,
                blockchainKey: publicKey.data,
                walletPublicKey: self.wallet.publicKey,
                curve: wallet.blockchain.curve
            )
            output = try AnySigner.signExternally(input: input, coin: .internetComputer, signer: coreSigner)
        } else {
            output = AnySigner.sign(input: input, coin: .internetComputer)
        }
        
        return output
    }
    
    func sendOld(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let dataForSign: Data
        do {
            dataForSign = try txBuilder.buildForSignOld(transaction: transaction)
        } catch {
            return .sendTxFail(error: WalletError.failedToBuildTx)
        }
        
        let publisher: AnyPublisher<Data, Error> = signer.sign(hash: dataForSign, walletPublicKey: wallet.publicKey)
        
        return publisher
            .flatMap { [weak self] data -> AnyPublisher<String, Error> in
                guard let self,
                      let rawTransactionData = try? txBuilder.buildForSendOld(
                          transaction: transaction,
                          signature: data
                      ) else {
                    return Fail(error: WalletError.failedToSendTx).eraseToAnyPublisher()
                }
                
                return networkService
                    .send(data: Data(hex: rawTransactionData))
                    .mapSendError(tx: rawTransactionData.lowercased())
                    .map { "" }
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .map { walletManager, transactionHash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: transactionHash)
                walletManager.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: transactionHash)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
    
    func send(
        _ transaction: Transaction,
        signer: TransactionSigner
    ) -> AnyPublisher<TransactionSendResult, SendTxError> {
        sendOld(transaction, signer: signer)
//        Just(())
//            .receive(on: DispatchQueue.global())
//            .tryMap { [txBuilder] _ in
//                try txBuilder.buildForSign(transaction: transaction)
//            }
//            .withWeakCaptureOf(self)
//            .flatMap { walletManager, input in
//                walletManager.buildTransaction(input: input, with: signer)
//                    .handleEvents(receiveOutput: { [weak self] output in
//                        self?.signingOutput = output
//                    })
//                    .withWeakCaptureOf(self)
//                    .tryMap { walletManager, output in
//                        try walletManager.txBuilder.buildForSend(output: output.callEnvelope)
//                    }
//                    .flatMap { signedTransaction in
//                        walletManager.networkService
//                            .send(data: signedTransaction)
//                            .handleEvents(receiveOutput: { [weak self] value in
//                                self?.trackStransactionStatus()
//                            })
//                            .map { TransactionSendResult(hash: "") }
//                            .mapSendError(tx: signedTransaction.hexString.lowercased())
//                    }
//            }
//            .eraseSendError()
//            .eraseToAnyPublisher()
    }
    
    private func trackStransactionStatus()  {
        guard let signingOutput,
              let signedRequest = try? txBuilder.buildForSend(output: signingOutput.readStateEnvelope) else { return }
        
        let paths = ICPStateTreePath.readStateRequestPaths(requestID: signingOutput.requestID)
        
        cancellable = networkService.readState(data: signedRequest, paths: paths)
            .sink(receiveCompletion: { [weak self] completion in
                self?.signingOutput = nil
            }, receiveValue: { [weak self] value in
                guard let value else {
                    self?.trackStransactionStatus()
                    return
                }
                self?.signingOutput = nil
            })
    }
}

extension ICPWalletManager {
    enum Constants {
        static let fee = Decimal(stringValue: "0.0001")!
    }
}
