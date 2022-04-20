//
//  TronWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class TronWalletManager: BaseManager, WalletManager {
    var currentHost: String {
        fatalError()
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    var networkService: TronNetworkService!
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService.accountInfo(for: wallet.address, tokens: cardTokens)
            .sink { [unowned self] in
                switch $0 {
                case .failure(let error):
                    self.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
                print($0)
            } receiveValue: { [unowned self] in
                print($0)
                self.updateWallet($0)
            }
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        let decimalAmount = transaction.amount.value * wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        
        return networkService.createTransaction(from: transaction.sourceAddress, to: transaction.destinationAddress, amount: intAmount)
            .flatMap { [weak self] request -> AnyPublisher<TronTransactionRequest, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.sign(request, with: signer)
            }
            .flatMap { [weak self] transaction -> AnyPublisher<TronBroadcastResponse, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.broadcastTransaction(transaction)
            }
            .tryMap { broadcastResponse -> Void in
                guard broadcastResponse.result == true else {
                    throw WalletError.failedToSendTx
                }
                
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    func sign(_ transaction: TronTransactionRequest, with signer: TransactionSigner) -> AnyPublisher<TronTransactionRequest, Error> {
        let wallet = self.wallet
        
        let rawData = Data(hex: transaction.raw_data_hex)
        let hash = rawData.sha256()
        
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap { [wallet] _ -> AnyPublisher<Data, Error> in
                return signer.sign(hash: hash, cardId: wallet.cardId, walletPublicKey: wallet.publicKey)
            }
            .tryMap { [weak self] signature -> TronTransactionRequest in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                let unmarshalledSignature = self.unmarshal(signature, hash: hash).hexString
                
                var newTransaction = transaction
                newTransaction.signature = [unmarshalledSignature]
                return newTransaction
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        Just([Amount(with: .tron(testnet: true), value: 0.000001)]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    private func updateWallet(_ accountInfo: TronAccountInfo) {
        let blockchain = wallet.blockchain
        wallet.add(amount: Amount(with: blockchain, value: accountInfo.balance))
                   
        for (token, tokenBalance) in accountInfo.tokenBalances {
            wallet.add(tokenValue: tokenBalance, for: token)
        }
    }
    
    private func unmarshal(_ signature: Data, hash: Data) -> Data {
        do {
            let walletPublicKey = wallet.publicKey.blockchainKey
            let secpSignature = try Secp256k1Signature(with: signature)
            let components = try secpSignature.unmarshal(with: walletPublicKey, hash: hash)
            
            return components.r + components.s + components.v
        } catch {
            print(error)
            return Data()
        }
    }
}

extension TronWalletManager: ThenProcessable {
    
}
