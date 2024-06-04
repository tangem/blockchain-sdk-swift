//
//  KoinosWalletManager.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 03.06.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

class KoinosWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        networkService.host
    }
    
    var allowsFeeSelection: Bool {
        false
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
    
    func validate(amount: Amount, fee: Fee) throws {
        let fee = fee.amount.value
        let amount = amount.value
        
        // TODO: [KOINOS] wallet.amounts[AmountType.FeeResource()]?.maxValue
        let currentMana = wallet.amounts[.reserve]?.value ?? .zero
        let availableBalanceForTransfer = currentMana - fee
        
        let balance = wallet.amounts[.coin]?.value ?? .zero
        
        if balance < fee {
            throw WalletError.empty // TODO: [KOINOS] throw something like `InsufficientBalance`
        }
        
        if currentMana < fee {
            // TODO: [KOINOS] wallet.amounts[AmountType.FeeResource()]?.maxValue
            let maxMana = wallet.amounts[.reserve]?.value ?? .zero
            // TODO: [KOINOS] throw something like `InsufficientMana`
            throw WalletError.empty
        }
        
        if amount > availableBalanceForTransfer {
            // TODO: [KOINOS] throw something like `ManaFeeExceedsBalance`
            throw WalletError.empty
        }
    }
    
    func send(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, any Error> {
        do {
            try validate(amount: transaction.amount, fee: transaction.fee)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
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
                .map { signature in
                    transactionBuilder.buildForSend(
                        transaction: transaction,
                        normalizedSignature: signature
                    )
                }
                .flatMap(networkService.submitTransaction)
                .map(\.id)
                .map(TransactionSendResult.init)
            }
            .eraseToAnyPublisher()
    }
    
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        networkService.getRCLimit()
            .map { [wallet] rcLimit in
                Fee(Amount(
                    with: wallet.blockchain,
                    type: .reserve, // TODO: [KOINOS] AmountType.FeeResource()
                    value: rcLimit
                ))
            }
            .map { [$0] }
            .eraseToAnyPublisher()
    }
}
