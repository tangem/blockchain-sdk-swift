//
//  SolanaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Solana_Swift

class SolanaWalletManager: BaseManager, WalletManager {
    var solanaSdk: Solana!
    var networkService: SolanaNetworkService!
    
    var currentHost: String { networkService.host }
    
    override func update(completion: @escaping (Result<(), Error>) -> Void) {
        let transactionIDs = wallet.transactions.compactMap { $0.hash }
        
        cancellable = networkService.getInfo(accountId: wallet.address, transactionIDs: transactionIDs)
            .sink { [unowned self] in
                switch $0 {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [unowned self] info in
                self.updateWallet(info: info)
            }
    }
    
    private func updateWallet(info: SolanaAccountInfoResponse) {
        self.wallet.add(coinValue: info.balance)
        
        for cardToken in cardTokens {
            let mintAddress = cardToken.contractAddress
            let balance = info.tokensByMint[mintAddress]?.balance ?? Decimal(0)
            self.wallet.add(tokenValue: balance, for: cardToken)
        }
        
        for (index, transaction) in wallet.transactions.enumerated() {
            if let hash = transaction.hash, info.confirmedTransactionIDs.contains(hash) {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
}

extension SolanaWalletManager: TransactionSender {
    public var allowsFeeSelection: Bool { false }
    
    public func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        let sendPublisher: AnyPublisher<TransactionID, Error>
        switch transaction.amount.type {
        case .coin:
            sendPublisher = sendSol(transaction, signer: signer)
        case .token(let token):
            sendPublisher = sendSplToken(transaction, token: token, signer: signer)
        case .reserve:
            return .emptyFail
        }
        
        return sendPublisher
            .tryMap { [weak self] transactionID in
                guard let self = self else {
                    throw WalletError.empty
                }
                var sentTransaction = transaction
                sentTransaction.hash = transactionID
                self.wallet.add(transaction: sentTransaction)
                
                return TransactionSendResult(hash: transactionID)
            }
            .eraseToAnyPublisher()
    }
    
    public func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let transactionFeePublisher = networkService
            .transactionFee(numberOfSignatures: 1)
            
        let accountCreationFeePublisher = accountCreationFee(destination: destination, amount: amount)
        
        return Publishers.Zip(transactionFeePublisher, accountCreationFeePublisher)
            .tryMap { [weak self] transactionFee, accountCreationFee in
                guard let self = self else {
                    throw WalletError.empty
                }
                                
                let blockchain = self.wallet.blockchain
                let amount = Amount(with: blockchain, type: .coin, value: transactionFee + accountCreationFee)
                return [Fee(amount)]
            }
            .eraseToAnyPublisher()
    }
    
    private func sendSol(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        /*  HACK:
            The account opening "fee" is not a fee at all, meaning it is not deducted from
            user's account automatically. Instead, it is an extra amount we HAVE TO provide for the rent
            during the account's first epoch. If we don't include this amount the node will not open
            the account and the money will be lost.
         
            The account opening fee we returned in getFee is used for display purposes only.
         */
        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)

        return accountCreationFee(destination: transaction.destinationAddress, amount: transaction.amount)
            .flatMap { [weak self] additionalAmount -> AnyPublisher<TransactionID, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                let decimalAmount = (transaction.amount.value + additionalAmount) * self.wallet.blockchain.decimalValue
                let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
                return self.networkService.sendSol(amount: intAmount, destinationAddress: transaction.destinationAddress, signer: signer)
            }
            .eraseToAnyPublisher()
    }
    
    private func sendSplToken(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        guard
            let associatedSourceTokenAccountAddress = associatedTokenAddress(accountAddress: transaction.sourceAddress, mintAddress: token.contractAddress)
        else {
            return .anyFail(error: BlockchainSdkError.failedToConvertPublicKey)
        }
        
        let decimalAmount = transaction.amount.value * token.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)

        return networkService.sendSplToken(
            amount: intAmount,
            sourceTokenAddress: associatedSourceTokenAccountAddress,
            destinationAddress: transaction.destinationAddress,
            token: token,
            signer: signer
        )
    }
    
    private func accountCreationFee(destination: String, amount: Amount) -> AnyPublisher<Decimal, Error> {
        let accountCreationFeePublisher: AnyPublisher<Decimal, Error>
        switch amount.type {
        case .coin:
            accountCreationFeePublisher = networkService.mainAccountCreationFee()
        case .token:
            accountCreationFeePublisher = networkService.tokenAccountCreationFee()
        case .reserve:
            return .anyFail(error: BlockchainSdkError.failedToLoadFee)
        }
        
        let accountExistsPublisher: AnyPublisher<Bool, Error> = networkService
            .getInfo(accountId: destination, transactionIDs: [])
            .map { info in
                switch amount.type {
                case .coin:
                    return info.accountExists
                case .token(let token):
                    let existingTokenAccount = info.tokensByMint[token.contractAddress]
                    return existingTokenAccount != nil
                case .reserve:
                    return false
                }
            }
            .eraseToAnyPublisher()
        
        let rentExemptionBalancePublisher = networkService
            .minimalBalanceForRentExemption()
            .tryMap { [weak self] balance -> Amount in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                return Amount(with: self.wallet.blockchain, value: balance)
            }
            .eraseToAnyPublisher()
        
        return Publishers.Zip3(accountCreationFeePublisher, accountExistsPublisher, rentExemptionBalancePublisher)
            .tryMap { accountCreationFee, accountExists, rentExemption in
                if accountExists {
                    return 0
                }
                
                if amount.type == .coin && amount >= rentExemption {
                    return 0
                }

                return accountCreationFee
            }
            .eraseToAnyPublisher()
    }
    
    private func associatedTokenAddress(accountAddress: String, mintAddress: String) -> String? {
        guard
            let accountPublicKey = PublicKey(string: accountAddress),
            let tokenMintPublicKey = PublicKey(string: mintAddress),
            case let .success(associatedSourceTokenAddress) = PublicKey.associatedTokenAddress(walletAddress: accountPublicKey, tokenMintAddress: tokenMintPublicKey)
        else {
            return nil
        }
        
        return associatedSourceTokenAddress.base58EncodedString
    }
}

extension SolanaWalletManager: RentProvider {
    func minimalBalanceForRentExemption() -> AnyPublisher<Amount, Error> {
        networkService.minimalBalanceForRentExemption()
            .tryMap { [weak self] balance in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                let blockchain = self.wallet.blockchain
                return Amount(with: blockchain, type: .coin, value: balance)
            }
            .eraseToAnyPublisher()
    }
    
    func rentAmount() -> AnyPublisher<Amount, Error> {
        networkService.accountRentFeePerEpoch()
            .tryMap { [weak self] fee in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                let blockchain = self.wallet.blockchain
                return Amount(with: blockchain, type: .coin, value: fee)
            }
            .eraseToAnyPublisher()
    }
}

extension SolanaWalletManager: ThenProcessable { }
