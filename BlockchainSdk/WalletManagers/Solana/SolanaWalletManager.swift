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
    
    public override func update(completion: @escaping (Result<(), Error>) -> Void) {
        
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
        Future { [unowned self] promise in
            self.solanaSdk.api.getFees(commitment: nil) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let fee):
                    guard let lamports = fee.feeCalculator?.lamportsPerSignature else {
                        promise(.failure(SolanaError.noFeeReturned))
                        return
                    }
                    
                    let blockchain = self.wallet.blockchain
                    let amount = Amount(with: blockchain, type: .coin, value: Decimal(lamports) / blockchain.decimalValue)
                    promise(.success([amount]))
                }
            }
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
