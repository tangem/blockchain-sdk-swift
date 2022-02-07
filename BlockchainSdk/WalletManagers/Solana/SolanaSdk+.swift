//
//  SolanaSdk+.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 21.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Solana_Swift

extension Api {
    func getFees(
        commitment: Commitment? = nil
    ) -> AnyPublisher<Fee, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }
                
                self.getFees(commitment: commitment) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    
    func getMinimumBalanceForRentExemption(
        dataLength: UInt64,
        commitment: Commitment? = "recent"
    ) -> AnyPublisher<UInt64, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }

                self.getMinimumBalanceForRentExemption(
                    dataLength: dataLength,
                    commitment: commitment
                ) { 
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAccountInfo<T: BufferLayout>(account: String, decodedTo: T.Type) -> AnyPublisher<BufferInfo<T>, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }
                
                self.getAccountInfo(account: account, decodedTo: T.self) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTokenAccountsByOwner<T: Decodable>(
        pubkey: String,
        mint: String? = nil,
        programId: String? = nil,
        configs: RequestConfiguration? = nil
    ) -> AnyPublisher<[T], Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }
                
                self.getTokenAccountsByOwner(pubkey: pubkey, mint: mint, programId: programId, configs: configs) {
                    (result: Result<[T], Error>) in
                    
                    switch result {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let accounts):
                        promise(.success(accounts))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getSignatureStatuses(pubkeys: [String], configs: RequestConfiguration? = nil) -> AnyPublisher<[SignatureStatus?], Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }
                
                self.getSignatureStatuses(pubkeys: pubkeys, configs: configs) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let statuses):
                        promise(.success(statuses))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension Action {
    func getCreatingTokenAccountFee() -> AnyPublisher<UInt64, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }
                
                self.getCreatingTokenAccountFee {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let fee):
                        promise(.success(fee))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func sendSOL(
        to destination: String,
        amount: UInt64,
        allowUnfundedRecipient: Bool = false,
        signer: Signer
    ) -> AnyPublisher<TransactionID, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }
                
                self.sendSOL(
                    to: destination,
                    amount: amount,
                    allowUnfundedRecipient: allowUnfundedRecipient,
                    signer: signer
                ) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let transactionID):
                        promise(.success(transactionID))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func sendSPLTokens(
        mintAddress: String,
        decimals: Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        allowUnfundedRecipient: Bool = false,
        signer: Signer
    ) -> AnyPublisher<TransactionID, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else {
                    promise(.failure(WalletError.empty))
                    return
                }
                
                self.sendSPLTokens(
                    mintAddress: mintAddress,
                    decimals: decimals,
                    from: fromPublicKey,
                    to: destinationAddress,
                    amount: amount,
                    allowUnfundedRecipient: allowUnfundedRecipient,
                    signer: signer
                ) {
                    switch $0 {
                    case .failure(let error):
                        promise(.failure(error))
                    case .success(let transactionID):
                        promise(.success(transactionID))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
