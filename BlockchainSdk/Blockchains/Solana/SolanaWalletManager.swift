//
//  SolanaWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import Solana_Swift

class SolanaWalletManager: BaseManager, WalletManager {
    var solanaSdk: Solana!
    var networkService: SolanaNetworkService!
    
    var currentHost: String { networkService.host }
    
    var usePriorityFees = !NFCUtils.isPoorNfcQualityDevice
    
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
    
    public func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let decimalValue: Decimal
        switch amount.type {
        case .coin:
            decimalValue = wallet.blockchain.decimalValue
        case .token(let token):
            decimalValue = token.decimalValue
        case .reserve:
            fatalError()
        }
        
        let intAmount = ((amount.value * decimalValue) .rounded() as NSDecimalNumber).uint64Value
        let publicKey = PublicKey(data: wallet.publicKey.blockchainKey)!
        
        return destinationAccountInfo(destination: destination, amount: amount)
            .withWeakCaptureOf(self)
            .flatMap { thisSolanaWalletManager, accountExists -> AnyPublisher<SolanaFeeParameters, Error> in
                thisSolanaWalletManager.feeParameters(
                    amount: amount,
                    destination: destination, 
                    destinationAccountExists: accountExists.accountExists
                )
                .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .flatMap { thisSolanaWalletManager, feeParameters  -> AnyPublisher<(Decimal, SolanaFeeParameters), Error> in
                thisSolanaWalletManager.networkService
                    .getFeeForMessage(
                        amount: intAmount,
                        computeUnitLimit: feeParameters.computeUnitLimit,
                        computeUnitPrice: feeParameters.computeUnitPrice,
                        destinationAddress: destination,
                        fromPublicKey: publicKey
                    )
                    .map {
                        ($0, feeParameters)
                    }
                    .eraseToAnyPublisher()
            }
            .map { [wallet] (feeForMessage, feeParameters) -> [Fee] in
                let totalFee = feeForMessage + feeParameters.accountCreationFee
                
                let blockchain = wallet.blockchain
                let amount = Amount(with: blockchain, type: .coin, value: totalFee)
                return [Fee(amount, parameters: feeParameters)]
            }
            .eraseToAnyPublisher()
    }
    
    private func feeParameters(amount: Amount, destination: String, destinationAccountExists: Bool) -> AnyPublisher<SolanaFeeParameters, Error> {
        return destinationAccountInfo(destination: destination, amount: amount)
            .withWeakCaptureOf(self)
            .map { thisSolanaWalletManager, destinationAccountInfo -> SolanaFeeParameters in
                let calculatedComputeUnitPrice = thisSolanaWalletManager.networkService.computeUnitPrice(
                    destinationAccountExists: destinationAccountExists
                )
                
                let computeUnitLimit: UInt32?
                let computeUnitPrice: UInt64?
                if thisSolanaWalletManager.usePriorityFees {
                    // https://www.helius.dev/blog/priority-fees-understanding-solanas-transaction-fee-mechanics
                    computeUnitLimit = (destinationAccountInfo.accountExists ? 200_000 : 400_000)
                    computeUnitPrice = calculatedComputeUnitPrice
                } else {
                    computeUnitLimit = nil
                    computeUnitPrice = nil
                }
                
                return SolanaFeeParameters(
                    computeUnitLimit: computeUnitLimit,
                    computeUnitPrice: computeUnitPrice,
                    accountCreationFee: destinationAccountInfo.accountCreationFee
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func sendSol(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        guard let solanaFeeParameters = transaction.fee.parameters as? SolanaFeeParameters else {
            return .anyFail(error: WalletError.failedToSendTx)
        }
        
        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)
        
        let decimalAmount = transaction.amount.value * self.wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        
        return self.networkService.sendSol(
            amount: intAmount,
            computeUnitLimit: solanaFeeParameters.computeUnitLimit,
            computeUnitPrice: solanaFeeParameters.computeUnitPrice,
            destinationAddress: transaction.destinationAddress,
            signer: signer
        )
    }
    
    private func sendSplToken(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TransactionID, Error> {
        guard let solanaFeeParameters = transaction.fee.parameters as? SolanaFeeParameters else {
            return .anyFail(error: WalletError.failedToSendTx)
        }
        
        let decimalAmount = transaction.amount.value * token.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        let signer = SolanaTransactionSigner(transactionSigner: signer, walletPublicKey: wallet.publicKey)
        
        let tokenProgramIdPublisher = networkService.tokenProgramId(contractAddress: token.contractAddress)
        let accountExistsPublisher = accountExists(destination: transaction.destinationAddress, amountType: transaction.amount.type)
        
        return tokenProgramIdPublisher
            .flatMap { [weak self] tokenProgramId -> AnyPublisher<TransactionID, Error> in
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
                    computeUnitLimit: solanaFeeParameters.computeUnitLimit,
                    computeUnitPrice: solanaFeeParameters.computeUnitPrice,
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
            // Include the fee if the amount is less than it
            accountCreationFeePublisher = networkService.mainAccountCreationFee()
                .map { accountCreationFee in
                    if amount.value < accountCreationFee {
                        return accountCreationFee
                    } else {
                        return .zero
                    }
                }
                .eraseToAnyPublisher()
            
            tokens = []
        case .token(let token):
            accountCreationFeePublisher = .justWithError(output: 0)
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
                let accountCreationFee: Decimal
                if accountExists {
                    accountCreationFee = 0
                } else if amount.type == .coin && amount >= rentExemption {
                    accountCreationFee = 0
                } else {
                    accountCreationFee = _accountCreationFee
                }
                
                return DestinationAccountInfo(accountExists: accountExists, accountCreationFee: accountCreationFee)
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
