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

enum SolanaWalletError: Error {
    case noFeeReturned
    case invalidAddress
}

class SolanaWalletManager: WalletManager {
    var solanaSdk: Solana!
    var networkService: SolanaNetworkService!
    
    public override func update(completion: @escaping (Result<(), Error>) -> Void) {
        cancellable = networkService
            .accountInfo(accountId: wallet.address)
            .sink { [unowned self] in
                switch $0 {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [unowned self] in
                self.updateWallet($0)
            }
    }
    
    private func updateWallet(_ response: SolanaAccountInfoResponse) {
        self.wallet.add(coinValue: response.balance)
        
        for cardToken in cardTokens {
            let mintAddress = cardToken.contractAddress
            let balance = response.tokensByMint[mintAddress]?.balance ?? Decimal(0)
            self.wallet.add(tokenValue: balance, for: cardToken)
        }
    }
}

extension SolanaWalletManager: TransactionSender {
    public var allowsFeeSelection: Bool { false }
    
    public func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        switch transaction.amount.type {
        case .coin:
            return sendSol(transaction, signer: signer)
        case .token(let token):
            return sendSplToken(transaction, token: token, signer: signer)
        case .reserve:
            return .emptyFail
        }
    }
    
    private func sendSol(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        Future { [unowned self] promise in
            let signer = SolanaTransactionSigner(transactionSigner: signer, cardId: self.wallet.cardId, walletPublicKey: self.wallet.publicKey)

            let lamport = NSDecimalNumber(decimal: transaction.amount.value * self.wallet.blockchain.decimalValue).uint64Value
            self.solanaSdk.action.sendSOL(to: transaction.destinationAddress, amount: lamport, allowUnfundedRecipient: true, signer: signer) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success:
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func sendSplToken(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        Future { [unowned self] promise in
            guard
                let associatedSourceTokenAccountAddress = associatedTokenAddress(accountAddress: transaction.sourceAddress, mintAddress: token.contractAddress)
            else {
                promise(.failure(SolanaWalletError.invalidAddress))
                return
            }
            
            let signer = SolanaTransactionSigner(transactionSigner: signer, cardId: self.wallet.cardId, walletPublicKey: self.wallet.publicKey)

            let lamport = NSDecimalNumber(decimal: transaction.amount.value * token.decimalValue).uint64Value
            
            self.solanaSdk.action.sendSPLTokens(
                mintAddress: token.contractAddress,
                decimals: Decimals(token.decimalCount),
                from: associatedSourceTokenAccountAddress,
                to: transaction.destinationAddress,
                amount: lamport,
                allowUnfundedRecipient: true,
                signer: signer
            ) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success:
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        networkService
            .fee(numberOfSignatures: 1)
            .map {
                let blockchain = self.wallet.blockchain
                return [Amount(with: blockchain, type: .coin, value: $0)]
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

extension SolanaWalletManager: ThenProcessable { }
