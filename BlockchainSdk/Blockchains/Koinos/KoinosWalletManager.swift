//
//  KoinosWalletManager.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 03.06.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine
import TangemSdk

class KoinosWalletManager: BaseManager, WalletManager, FeeResourceRestrictable {
    var currentHost: String {
        networkService.host
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    var feeResourceType: FeeResourceType {
        .mana
    }
    
    private let networkService: KoinosNetworkService
    private let transactionBuilder: KoinosTransactionBuilder
    
    init(
        wallet: Wallet,
        networkService: KoinosNetworkService,
        transactionBuilder: KoinosTransactionBuilder
    ) {
        self.networkService = networkService
        self.transactionBuilder = transactionBuilder
        super.init(wallet: wallet)
    }
    
    override func update(completion: @escaping (Result<Void, any Error>) -> Void) {
        let isPendingTransactionExist = Just(wallet.pendingTransactions.first?.hash)
            .flatMap { [networkService] transactionID in
                if let transactionID {
                    return networkService
                        .isTransactionExist(transactionID: transactionID)
                        .map(Optional.some)
                        .eraseToAnyPublisher()
                }
                return Just<Bool?>(nil)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        
        cancellable = Publishers.CombineLatest(
            networkService.getInfo(address: wallet.address),
            isPendingTransactionExist
        )
        .sink { [weak self] in
            switch $0 {
            case .failure(let error):
                self?.wallet.clearAmounts()
                completion(.failure(error))
            case .finished:
                completion(.success(()))
            }
        } receiveValue: { [weak self] accountInfo, isPendingTransactionExist in
            guard let self else { return }
            
            let atomicUnitMultiplier = wallet.blockchain.decimalValue
            let koinBalance = Decimal(accountInfo.koinBalance) / atomicUnitMultiplier
            let mana = Decimal(accountInfo.mana) / atomicUnitMultiplier
            
            wallet.add(
                amount: Amount(
                    with: wallet.blockchain,
                    type: .coin,
                    value: koinBalance
                )
            )
            wallet.add(
                amount: Amount(
                    with: self.wallet.blockchain,
                    type: .feeResource(.mana),
                    value: mana
                )
            )
            
            if isPendingTransactionExist == true {
                wallet.clearPendingTransaction()
            }
        }
    }
    
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let manaLimit = transaction.fee.amount.value
        let transactionDataWithMana = transaction.then {
            $0.params = KoinosTransactionParams(manaLimit: manaLimit)
        }
        
        return networkService.getCurrentNonce(address: wallet.address)
            .tryMap { [transactionBuilder] nonce in
                try transactionBuilder.buildForSign(
                    transaction: transactionDataWithMana,
                    currentNonce: nonce
                )
            }
            .flatMap { [wallet, transactionBuilder, networkService] transaction, hashToSign in
                signer.sign(
                    hash: hashToSign,
                    walletPublicKey: wallet.publicKey
                )
                .tryMap { signature in
                    try transactionBuilder.buildForSend(
                        transaction: transaction,
                        signature: signature
                    )
                }
                .flatMap(networkService.submitTransaction)
                .map(\.id)
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
    
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        networkService.getRCLimit()
            .map { [blockchain = wallet.blockchain] rcLimit in
                Fee(
                    Amount(
                        type: .feeResource(.mana),
                        currencySymbol: FeeResourceType.mana.rawValue,
                        value: (rcLimit.decimal ?? .zero) / blockchain.decimalValue,
                        decimals: blockchain.decimalCount
                    )
                )
            }
            .map { [$0] }
            .eraseToAnyPublisher()
    }
}
