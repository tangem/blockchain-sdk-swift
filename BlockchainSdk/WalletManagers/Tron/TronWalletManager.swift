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
    
    private static let feeSigner = DummySigner()
    
    func update(completion: @escaping (Result<Void, Error>) -> Void) {
        let transactionIDs = wallet.transactions
            .filter { $0.status == .unconfirmed }
            .compactMap { $0.hash }
        
        cancellable = networkService.accountInfo(for: wallet.address, tokens: cardTokens, transactionIDs: transactionIDs)
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
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        let sendPublisher: AnyPublisher<TronBroadcastResponse, Error>
        switch transaction.amount.type {
        case .reserve:
            return .anyFail(error: WalletError.failedToBuildTx)
        case .coin:
            sendPublisher = sendTrx(transaction, signer: signer)
        case .token(let token):
            sendPublisher = sendTrc20(transaction, token: token, signer: signer)
        }
        
        return sendPublisher
            .tryMap { [weak self] broadcastResponse -> Void in
                guard broadcastResponse.result == true else {
                    throw WalletError.failedToSendTx
                }
                
                var submittedTransaction = transaction
                submittedTransaction.hash = broadcastResponse.txid
                self?.wallet.transactions.append(submittedTransaction)
                
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        let transactionPiecesPublisher: AnyPublisher<(String, String), Error>
        let estimatedEnergyUsePublisher: AnyPublisher<Int, Error>

        switch amount.type {
        case .reserve:
            return .anyFail(error: WalletError.failedToGetFee)
        case .coin:
            transactionPiecesPublisher = signedTrxTransaction(from: wallet.address, to: destination, amount: amount, signer: Self.feeSigner, publicKey: Self.feeSigner.publicKey)
                .map {
                    ($0.raw_data_hex, $0.signature?.first ?? "")
                }
                .eraseToAnyPublisher()
            
            estimatedEnergyUsePublisher = Just(0).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .token(let token):
            transactionPiecesPublisher = signedTrc20Transaction(from: wallet.address, to: destination, contractAddress: token.contractAddress, amount: amount, signer: Self.feeSigner, publicKey: Self.feeSigner.publicKey)
                .map {
                    ($0.raw_data_hex, $0.signature?.first ?? "")
                }
                .eraseToAnyPublisher()
            
            estimatedEnergyUsePublisher = networkService.tokenTransferMaxEnergyUse(contractAddress: token.contractAddress)
        }
        
        let blockchain = self.wallet.blockchain
        
        return networkService.getAccountResource(for: wallet.address)
            .zip(networkService.accountExists(address: destination), transactionPiecesPublisher, estimatedEnergyUsePublisher)
            .map { (resources, destinationExists, transactionPieces, estimatedEnergyUse) -> Amount in
                if !destinationExists {
                    return Amount(with: blockchain, value: 1.1)
                }
                
                let additionalDataSize = 69
                let transactionByteSize = (Data(hex: transactionPieces.0) + Data(hex: transactionPieces.1)).count + additionalDataSize
                let sunPerTransactionByte = 1000
                let transactionSizeFee = transactionByteSize * sunPerTransactionByte
                
                let sunPerEnergyUnit = 280
                let energyFee = estimatedEnergyUse * sunPerEnergyUnit
                
                let totalFee = transactionSizeFee + energyFee
                
                let remainingBandwidthInSun = (resources.freeNetLimit - (resources.freeNetUsed ?? 0)) * 1000
                
                if totalFee <= remainingBandwidthInSun {
                    return .zeroCoin(for: blockchain)
                } else {
                    let value = Decimal(totalFee) / blockchain.decimalValue
                    return Amount(with: blockchain, value: value)
                }
            }
            .map {
                [$0]
            }
            .eraseToAnyPublisher()
    }
    
    private func signedTrxTransaction(from source: String,
                                      to destination: String,
                                      amount: Amount,
                                      signer: TransactionSigner,
                                      publicKey: Wallet.PublicKey
    ) -> AnyPublisher<TronTransactionRequest<TrxTransferValue>, Error> {
        return networkService.createTransaction(from: source, to: destination, amount: uint64(from: amount))
            .flatMap { [weak self] transaction -> AnyPublisher<TronTransactionRequest<TrxTransferValue>, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.sign(transaction, with: signer, publicKey: publicKey)
            }
            .eraseToAnyPublisher()
    }
    
    private func signedTrc20Transaction(from source: String,
                                        to destination: String,
                                        contractAddress: String,
                                        amount: Amount,
                                        signer: TransactionSigner,
                                        publicKey: Wallet.PublicKey
    ) -> AnyPublisher<TronTransactionRequest<Trc20TransferValue>, Error> {
        return networkService.createTrc20Transaction(from: source, to: destination, contractAddress: contractAddress, amount: uint64(from: amount))
            .map(\.transaction)
            .flatMap { [weak self] transaction -> AnyPublisher<TronTransactionRequest<Trc20TransferValue>, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.sign(transaction, with: signer, publicKey: publicKey)
            }
            .eraseToAnyPublisher()
    }
    
    private func sign<T: Codable>(_ transaction: TronTransactionRequest<T>, with signer: TransactionSigner, publicKey: Wallet.PublicKey) -> AnyPublisher<TronTransactionRequest<T>, Error> {
        let wallet = self.wallet
        
        let rawData = Data(hex: transaction.raw_data_hex)
        let hash = rawData.sha256()
        
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap { [wallet] _ -> AnyPublisher<Data, Error> in
                return signer.sign(hash: hash, cardId: wallet.cardId, walletPublicKey: publicKey)
            }
            .tryMap { [weak self] signature -> TronTransactionRequest in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                let unmarshalledSignature = self.unmarshal(signature, hash: hash, publicKey: publicKey).hexString
                
                var newTransaction = transaction
                newTransaction.signature = [unmarshalledSignature]
                return newTransaction
            }
            .eraseToAnyPublisher()
    }
    
    private func sendTrx(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TronBroadcastResponse, Error> {
        return signedTrxTransaction(from: transaction.sourceAddress, to: transaction.destinationAddress, amount: transaction.amount, signer: signer, publicKey: wallet.publicKey)
            .flatMap { [weak self] transaction -> AnyPublisher<TronBroadcastResponse, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.broadcastTransaction(transaction)
            }
            .eraseToAnyPublisher()
    }
    
    private func sendTrc20(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<TronBroadcastResponse, Error> {
        return signedTrc20Transaction(from: transaction.sourceAddress, to: transaction.destinationAddress, contractAddress: token.contractAddress, amount: transaction.amount, signer: signer, publicKey: wallet.publicKey)
            .flatMap { [weak self] transaction -> AnyPublisher<TronBroadcastResponse, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.broadcastTransaction(transaction)
            }
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(_ accountInfo: TronAccountInfo) {
        let blockchain = wallet.blockchain
        wallet.add(amount: Amount(with: blockchain, value: accountInfo.balance))
        
        for (token, tokenBalance) in accountInfo.tokenBalances {
            wallet.add(tokenValue: tokenBalance, for: token)
        }
        
        for (index, transaction) in wallet.transactions.enumerated() {
            if let hash = transaction.hash, accountInfo.confirmedTransactionIDs.contains(hash) {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
    
    private func unmarshal(_ signature: Data, hash: Data, publicKey: Wallet.PublicKey) -> Data {
        guard publicKey != Self.feeSigner.publicKey else {
            return signature + Data(0)
        }
        
        do {
            let secpSignature = try Secp256k1Signature(with: signature)
            let components = try secpSignature.unmarshal(with: publicKey.blockchainKey, hash: hash)
            
            return components.r + components.s + components.v
        } catch {
            print(error)
            return Data()
        }
    }
    
    private func uint64(from amount: Amount) -> UInt64 {
        let decimalValue: Decimal
        switch amount.type {
        case .coin:
            decimalValue = wallet.blockchain.decimalValue
        case .token(let token):
            decimalValue = token.decimalValue
        case .reserve:
            fatalError()
        }
        
        let decimalAmount = amount.value * decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        return intAmount
    }
}

extension TronWalletManager: ThenProcessable {
    
}


fileprivate class DummySigner: TransactionSigner {
    let privateKey: Data
    let publicKey: Wallet.PublicKey
    
    init() {
        let keyPair = try! Secp256k1Utils().generateKeyPair()
        let compressedPublicKey = try! Secp256k1Key(with: keyPair.publicKey).compress()
        self.publicKey = Wallet.PublicKey(seedKey: compressedPublicKey, derivedKey: nil, derivationPath: nil)
        self.privateKey = keyPair.privateKey
    }
    
    func sign(hashes: [Data], cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        fatalError()
    }
    
    func sign(hash: Data, cardId: String, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        do {
            let signature = try Secp256k1Utils().sign(hash, with: privateKey)
            return Just(signature)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
}
