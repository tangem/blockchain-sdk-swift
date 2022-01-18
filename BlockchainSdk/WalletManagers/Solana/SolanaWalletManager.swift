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

enum SolanaError: Error {
    case noFeeReturned
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
            let contractAddress = cardToken.contractAddress
            guard let responseToken = response.tokens.first(where: {
                $0.mint == contractAddress
            }) else {
                continue
            }
            
            self.wallet.add(tokenValue: responseToken.balance, for: cardToken)
        }
    }
}

extension SolanaWalletManager: TransactionSender {
    public var allowsFeeSelection: Bool { false }
    
    public func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        Future { [unowned self] promise in
            let signer = SolanaTransactionSigner(transactionSigner: signer, cardId: self.wallet.cardId, walletPublicKey: self.wallet.publicKey)

            let lamport = NSDecimalNumber(decimal: transaction.amount.value * self.wallet.blockchain.decimalValue).uint64Value
            self.solanaSdk.action.sendSOL(to: transaction.destinationAddress, amount: lamport, signer: signer) { result in
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
}

fileprivate class SolanaTransactionSigner: Signer {
    var publicKey: PublicKey {
        PublicKey(data: walletPublicKey.blockchainKey)!
    }
    
    let transactionSigner: TransactionSigner
    let cardId: String
    let walletPublicKey: Wallet.PublicKey
    
    var subscriptions: Set<AnyCancellable> = []
    
    init(transactionSigner: TransactionSigner, cardId: String, walletPublicKey: Wallet.PublicKey) {
        self.transactionSigner = transactionSigner
        self.cardId = cardId
        self.walletPublicKey = walletPublicKey
    }
    
    func sign(message: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        transactionSigner.sign(hash: message, cardId: cardId, walletPublicKey: walletPublicKey)
            .sink { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    break
                }
            } receiveValue: { data in
                completion(.success(data))
            }
            .store(in: &subscriptions)
    }
}

extension SolanaWalletManager: ThenProcessable { }
