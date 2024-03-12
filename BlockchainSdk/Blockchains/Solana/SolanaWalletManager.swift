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
        let transactionIDs = wallet.pendingTransactions.map { $0.hash }
        
        cancellable = networkService.getInfo(accountId: wallet.address, tokens: cardTokens, transactionIDs: transactionIDs)
            .sink { [weak self] in
                switch $0 {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] info in
                self?.updateWallet(info: info)
            }
    }
    
    private func updateWallet(info: SolanaAccountInfoResponse) {
        self.wallet.add(coinValue: info.balance)
        
        for cardToken in cardTokens {
            let mintAddress = cardToken.contractAddress
            let balance = info.tokensByMint[mintAddress]?.balance ?? Decimal(0)
            self.wallet.add(tokenValue: balance, for: cardToken)
        }
        
        wallet.removePendingTransaction { hash in
            info.confirmedTransactionIDs.contains(hash)
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
            .tryMap { [weak self] hash in
                guard let self = self else {
                    throw WalletError.empty
                }

                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                self.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: hash)
            }
            .eraseToAnyPublisher()
    }
    
    func estimatedFee(amount: Amount) -> AnyPublisher<[Fee], Error> {
        networkService
            .transactionFee(numberOfSignatures: 1)
            .tryMap { [weak self] transactionFee in
                guard let self = self else {
                    throw WalletError.empty
                }
                                
                let blockchain = self.wallet.blockchain
                let amount = Amount(with: blockchain, type: .coin, value: transactionFee)
                return [Fee(amount)]
            }
            .eraseToAnyPublisher()
    }
    
    public func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let transactionFeePublisher = networkService
            .transactionFee(numberOfSignatures: 1)
            
        let accountCreationFeePublisher = destinationAccountInfo(destination: destination, amount: amount)
            .map(\.accountCreationFee)
        
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
    
    private func computeUnitLimit(accountExists: Bool) -> UInt32 {
        accountExists ? 200_000 : 400_000
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
        
        let accountCreationInfoPublisher = destinationAccountInfo(
            destination: transaction.destinationAddress, 
            amount: transaction.amount
        )
        let averagePrioritizationFeePublisher = networkService.averagePrioritizationFee(
            accounts: [transaction.sourceAddress, transaction.destinationAddress]
        )
        
        return Publishers.CombineLatest(accountCreationInfoPublisher, averagePrioritizationFeePublisher)
            .flatMap { [weak self] accountCreationInfo, averagePrioritizationFee -> AnyPublisher<TransactionID, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                let decimalAmount = (transaction.amount.value + accountCreationInfo.accountCreationFee) * self.wallet.blockchain.decimalValue
                let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
                
                return self.networkService.sendSol(
                    amount: intAmount,
                    computeUnitLimit: self.computeUnitLimit(accountExists: accountCreationInfo.accountExists),
                    computeUnitPrice: averagePrioritizationFee,
                    destinationAddress: transaction.destinationAddress,
                    signer: signer
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func sendSplToken(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        let decimalAmount = transaction.amount.value * token.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)
        
        let tokenProgramIdPublisher = networkService.tokenProgramId(contractAddress: token.contractAddress)
        let accountExistsPublisher = accountExists(destination: transaction.destinationAddress, amountType: transaction.amount.type)
        
        return Publishers.CombineLatest(tokenProgramIdPublisher, accountExistsPublisher)
            .flatMap { [weak self] tokenProgramId, accountExists -> AnyPublisher<(PublicKey, UInt32, UInt64), Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                guard let associatedDestinationTokenAddress = associatedTokenAddress(
                    accountAddress: transaction.destinationAddress,
                    mintAddress: token.contractAddress,
                    tokenProgramId: tokenProgramId
                ) else {
                    return .anyFail(error: BlockchainSdkError.failedToConvertPublicKey)
                }
                
                let computeUnitLimit = self.computeUnitLimit(accountExists: accountExists)
                
                return Publishers.CombineLatest3(
                    Just(tokenProgramId).setFailureType(to: Error.self).eraseToAnyPublisher(),
                    Just(computeUnitLimit).setFailureType(to: Error.self).eraseToAnyPublisher(),
                    self.networkService.averagePrioritizationFee(accounts: [transaction.sourceAddress, associatedDestinationTokenAddress])
                ) .eraseToAnyPublisher()
            }
            .flatMap { [weak self] tokenProgramId, computeUnitLimit, computeUnitPrice -> AnyPublisher<TransactionID, Error> in
                guard let self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                guard
                    let associatedSourceTokenAccountAddress = self.associatedTokenAddress(accountAddress: transaction.sourceAddress, mintAddress: token.contractAddress, tokenProgramId: tokenProgramId)
                else {
                    return .anyFail(error: BlockchainSdkError.failedToConvertPublicKey)
                }
                
                return self.networkService.sendSplToken(
                    amount: intAmount,
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    sourceTokenAddress: associatedSourceTokenAccountAddress,
                    destinationAddress: transaction.destinationAddress,
                    token: token,
                    tokenProgramId: tokenProgramId,
                    signer: signer
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func accountExists(destination: String, amountType: Amount.AmountType) -> AnyPublisher<Bool, Error> {
        let tokens: [Token]
        if case .token(let token) = amountType {
            tokens = [token]
        } else {
            tokens = []
        }
        
        return networkService
            .getInfo(accountId: destination, tokens: tokens, transactionIDs: [])
            .map { info in
                switch amountType {
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
    }
    
    
    private func destinationAccountInfo(destination: String, amount: Amount) -> AnyPublisher<DestinationAccountInfo, Error> {
        let accountCreationFeePublisher: AnyPublisher<Decimal, Error>
        let tokens: [Token]
        switch amount.type {
        case .coin:
            accountCreationFeePublisher = networkService.mainAccountCreationFee()
            tokens = []
        case .token(let token):
            accountCreationFeePublisher = networkService.tokenAccountCreationFee()
            tokens = [token]
        case .reserve:
            return .anyFail(error: BlockchainSdkError.failedToLoadFee)
        }
        
        let accountExistsPublisher: AnyPublisher<Bool, Error> = networkService
            .getInfo(accountId: destination, tokens: tokens, transactionIDs: [])
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
            .tryMap { _accountCreationFee, accountExists, rentExemption in
                let accountCreationFeeValue: Decimal
                if accountExists {
                    accountCreationFeeValue = 0
                } else if amount.type == .coin && amount >= rentExemption {
                    accountCreationFeeValue = 0
                } else {
                    accountCreationFeeValue = _accountCreationFee
                }
                
                return DestinationAccountInfo(accountExists: accountExists, accountCreationFee: accountCreationFeeValue)
            }
            .eraseToAnyPublisher()
    }
    
    private func associatedTokenAddress(accountAddress: String, mintAddress: String, tokenProgramId: PublicKey) -> String? {
        guard
            let accountPublicKey = PublicKey(string: accountAddress),
            let tokenMintPublicKey = PublicKey(string: mintAddress),
            case let .success(associatedSourceTokenAddress) = PublicKey.associatedTokenAddress(walletAddress: accountPublicKey, tokenMintAddress: tokenMintPublicKey, tokenProgramId: tokenProgramId)
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

private extension SolanaWalletManager {
    struct DestinationAccountInfo {
        let accountExists: Bool
        let accountCreationFee: Decimal
    }
}
