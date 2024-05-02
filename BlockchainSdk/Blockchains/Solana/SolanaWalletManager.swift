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
    
    public func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        let sendPublisher: AnyPublisher<TransactionID, Error>
        switch transaction.amount.type {
        case .coin:
            sendPublisher = sendSol(transaction, signer: signer)
        case .token(let token):
            sendPublisher = sendSplToken(transaction, token: token, signer: signer)
        case .reserve:
            return .sendFail(error: WalletError.empty)
        }
        
        return sendPublisher
            .tryMap { [weak self] hash in
                guard let self else {
                    throw WalletError.empty
                }

                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                self.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: hash)
            }
            .mapError {
                SendTxError(error: $0)
            }
            .eraseToAnyPublisher()
    }
    
    public func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        destinationAccountInfo(destination: destination, amount: amount)
            .withWeakCaptureOf(self)
            .flatMap { walletManager, destinationAccountInfo in
                let feeParameters = walletManager.feeParameters(destinationAccountInfo: destinationAccountInfo)
                let decimalValue: Decimal = pow(10, amount.decimals)
                let intAmount = (amount.value * decimalValue).rounded().uint64Value

                return walletManager.networkService.getFeeForMessage(
                    amount: intAmount,
                    computeUnitLimit: feeParameters.computeUnitLimit,
                    computeUnitPrice: feeParameters.computeUnitPrice,
                    destinationAddress: destination,
                    fromPublicKey: PublicKey(data: walletManager.wallet.publicKey.blockchainKey)!
                )
                .map { (feeForMessage: $0, feeParameters: feeParameters) }
            }
            .withWeakCaptureOf(self)
            .map { walletManger, feeInfo -> [Fee] in
                let totalFee = feeInfo.feeForMessage + feeInfo.feeParameters.accountCreationFee
                let amount = Amount(with: walletManger.wallet.blockchain, type: .coin, value: totalFee)
                return [Fee(amount, parameters: feeInfo.feeParameters)]
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

private extension SolanaWalletManager {
    /// Combine `accountCreationFeePublisher`, `accountExistsPublisher` and `minimalBalanceForRentExemption`
    func destinationAccountInfo(destination: String, amount: Amount) -> AnyPublisher<DestinationAccountInfo, Error> {
        let accountCreationFeePublisher = accountCreationFeePublisher(amount: amount)
        let accountExistsPublisher = accountExists(destination: destination, amountType: amount.type)
        let rentExemptionBalancePublisher = networkService.minimalBalanceForRentExemption()

        return Publishers.Zip3(accountCreationFeePublisher, accountExistsPublisher, rentExemptionBalancePublisher)
            .map { accountCreationFee, accountExists, rentExemption in
                let creationFee: Decimal
                if accountExists {
                    creationFee = 0
                } else if amount.type == .coin && amount.value >= rentExemption {
                    creationFee = 0
                } else {
                    creationFee = accountCreationFee
                }

                return DestinationAccountInfo(accountExists: accountExists, accountCreationFee: creationFee)
            }
            .eraseToAnyPublisher()
    }

    func accountExists(destination: String, amountType: Amount.AmountType) -> AnyPublisher<Bool, Error> {
        let tokens: [Token] = amountType.token.map { [$0] } ?? []

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

    func accountCreationFeePublisher(amount: Amount) -> AnyPublisher<Decimal, Error> {
        switch amount.type {
        case .coin:
            // Include the fee if the amount is less than it
            return networkService.mainAccountCreationFee()
                .map { accountCreationFee in
                    if amount.value < accountCreationFee {
                        return accountCreationFee
                    } else {
                        return .zero
                    }
                }
                .eraseToAnyPublisher()
        case .token:
            return .justWithError(output: 0)
        case .reserve:
            return .anyFail(error: BlockchainSdkError.failedToLoadFee)
        }
    }

    func feeParameters(destinationAccountInfo: DestinationAccountInfo) -> SolanaFeeParameters {
        let computeUnitLimit: UInt32?
        let computeUnitPrice: UInt64?

        if usePriorityFees {
            // https://www.helius.dev/blog/priority-fees-understanding-solanas-transaction-fee-mechanics
            computeUnitLimit = destinationAccountInfo.accountExists ? 200_000 : 400_000
            computeUnitPrice = destinationAccountInfo.accountExists ? 1_000_000 : 500_000
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
