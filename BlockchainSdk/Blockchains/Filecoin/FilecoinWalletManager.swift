//
//  FilecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 30.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine

class FilecoinWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    private let networkService: FilecoinNetworkService
    private let transactionBuilder: FilecoinTransactionBuilder
    
    private var nonce: UInt64 = 0
    
    init(
        wallet: Wallet,
        networkService: FilecoinNetworkService,
        transactionBuilder: FilecoinTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        cancellable = networkService
            .getAccountInfo(address: wallet.address)
            .withWeakCaptureOf(self)
            .sink(
                receiveCompletion: {
                    _ in
                    
                },
                receiveValue: { walletManager, accountInfo in
                    if accountInfo.nonce != walletManager.nonce {
                        walletManager.wallet.clearPendingTransaction()
                    }
                    
                    walletManager.wallet.add(
                        amount: Amount(
                            with: .filecoin,
                            type: .coin,
                            value: accountInfo.balance / walletManager.wallet.blockchain.decimalValue
                        )
                    )
                    
                    walletManager.nonce = accountInfo.nonce
                }
            )
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        let transactionInfo = FilecoinTxInfo(
            sourceAddress: wallet.address,
            destinationAddress: destination,
            amount: amount.value.uint64Value,
            nonce: nonce
        )
        
        return networkService
            .getMessageGas(transactionInfo: transactionInfo)
            .withWeakCaptureOf(self)
            .tryMap { (walletManager: FilecoinWalletManager, gasInfo) -> [Fee] in
                guard let gasLimitDecimal = gasInfo.gasLimit.decimal,
                      let gasUnitPriceDecimal = gasInfo.gasUnitPrice.decimal
                else {
                    throw WalletError.failedToGetFee
                }
                
                return [
                    Fee(
                        Amount(
                            with: .filecoin,
                            type: .coin,
                            value: (gasLimitDecimal * gasUnitPriceDecimal) / walletManager.wallet.blockchain.decimalValue
                        ),
                        parameters: FilecoinFeeParameters(
                            gasUnitPrice: gasInfo.gasUnitPrice,
                            gasLimit: gasLimitDecimal.int64Value,
                            gasPremium: gasInfo.gasPremium
                        )
                    )
                ]
            }
            .eraseToAnyPublisher()
    }
    
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Result {
            try transactionBuilder.buildForSign(transaction: transaction, nonce: nonce)
        }
        .publisher
        .withWeakCaptureOf(self)
        .flatMap { walletManager, hashToSign in
            signer
                .sign(hash: hashToSign, walletPublicKey: walletManager.wallet.publicKey)
                .withWeakCaptureOf(walletManager)
                .tryMap { walletManager, signature in
                    try walletManager.transactionBuilder.buildForSend(
                        transaction: transaction,
                        nonce: walletManager.nonce,
                        signatureInfo: SignatureInfo(
                            signature: signature,
                            publicKey: walletManager.wallet.publicKey.blockchainKey,
                            hash: hashToSign
                        )
                    )
                }
        }
        .withWeakCaptureOf(self)
        .flatMap { walletManager, body in
            walletManager.networkService.submitTransaction(signedTransactionBody: body)
        }
        .withWeakCaptureOf(self)
        .map { walletManager, txId in
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: txId)
            walletManager.wallet.addPendingTransaction(record)
            return TransactionSendResult(hash: txId)
        }
        .mapError { SendTxError(error: $0) }
        .eraseToAnyPublisher()
    }
}
