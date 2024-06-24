//
//  KoinosWalletManager.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 03.06.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation
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
        cancellable = networkService.getInfo(address: wallet.address)
            .sink { [weak self] in
                switch $0 {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] accountInfo in
                guard let self else { return }
                
                if wallet.amounts[.coin]?.value != accountInfo.koinBalance {
                    wallet.clearPendingTransaction()
                }
                
                wallet.add(
                    amount: Amount(
                        with: self.wallet.blockchain,
                        type: .coin,
                        value: accountInfo.koinBalance
                    )
                )
                wallet.add(
                    amount: Amount(
                        with: self.wallet.blockchain,
                        type: .feeResource(.mana),
                        value: accountInfo.mana
                    )
                )
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
                    let extendedSignature = try Secp256k1Signature(with: signature)
                        .unmarshal(with: wallet.publicKey.blockchainKey, hash: hashToSign)
                    
                    let recId = extendedSignature.v.bytes[0] - 27
                    let newV = recId + 31
                    return Data([newV]) + extendedSignature.r + extendedSignature.s
                }
                .map { preparedSignature in
                    transactionBuilder.buildForSend(
                        transaction: transaction,
                        preparedSignature: preparedSignature
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
            .map { [wallet] rcLimit in
                Fee(
                    Amount(
                        type: .feeResource(.mana),
                        currencySymbol: FeeResourceType.mana.rawValue,
                        value: rcLimit,
                        decimals: wallet.blockchain.decimalCount
                    )
                )
            }
            .map { [$0] }
            .eraseToAnyPublisher()
    }
}
