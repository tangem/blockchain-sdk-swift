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
        let signer = SolanaTransactionSigner(transactionSigner: signer, cardId: wallet.cardId, walletPublicKey: wallet.publicKey)
        let amount = NSDecimalNumber(decimal: transaction.amount.value * wallet.blockchain.decimalValue).uint64Value
        let destination = transaction.destinationAddress
        return networkService.sendSol(amount: amount, destinationAddress: destination, signer: signer)
    }
    
    private func sendSplToken(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard
            let associatedSourceTokenAccountAddress = associatedTokenAddress(accountAddress: transaction.sourceAddress, mintAddress: token.contractAddress)
        else {
            return .anyFail(error: SolanaWalletError.invalidAddress)
        }
        
        let lamport = NSDecimalNumber(decimal: transaction.amount.value * token.decimalValue).uint64Value

        
        let signer = SolanaTransactionSigner(transactionSigner: signer, cardId: wallet.cardId, walletPublicKey: wallet.publicKey)
        return networkService.sendSplToken(amount: lamport, sourceTokenAddress: associatedSourceTokenAccountAddress, destinationAddress: transaction.destinationAddress, token: token, signer: signer)
    }
    
    public func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        networkService
            .transactionFee(numberOfSignatures: 1)
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
