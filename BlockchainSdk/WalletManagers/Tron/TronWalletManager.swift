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
        switch transaction.amount.type {
        case .coin:
            return sendTrx(transaction, signer: signer)
        case .token(let token):
            return sendTrc20(transaction, token: token, signer: signer)
        default:
            return .anyFail(error: WalletError.failedToBuildTx)
        }
    }
    
    func sendTrx(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        let decimalAmount = transaction.amount.value * wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        
        return networkService.createTransaction(from: transaction.sourceAddress, to: transaction.destinationAddress, amount: intAmount)
            .flatMap { [weak self] request -> AnyPublisher<TronTransactionRequest, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.sign(request, with: signer, publicKey: self.wallet.publicKey.blockchainKey)
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
    
    func sendTrc20(_ transaction: Transaction, token: Token, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        let decimalAmount = transaction.amount.value * wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
        
        return networkService.createTrc20Transaction(from: transaction.sourceAddress, to: transaction.destinationAddress, contractAddress: token.contractAddress, amount: intAmount)
            .flatMap { [weak self] request -> AnyPublisher<TronTransactionRequest2, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.sign2(request, with: signer, publicKey: self.wallet.publicKey.blockchainKey)
            }
            .flatMap { [weak self] transaction -> AnyPublisher<TronBroadcastResponse, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.broadcastTransaction2(transaction)
            }
            .tryMap { broadcastResponse -> Void in
                guard broadcastResponse.result == true else {
                    throw WalletError.failedToSendTx
                }
                
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    func sign(_ transaction: TronTransactionRequest, with signer: TransactionSigner, publicKey: Data) -> AnyPublisher<TronTransactionRequest, Error> {
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
                
                let unmarshalledSignature = self.unmarshal(signature, hash: hash, publicKey: publicKey).hexString
                
                var newTransaction = transaction
                newTransaction.signature = [unmarshalledSignature]
                return newTransaction
            }
            .eraseToAnyPublisher()
    }
    
    func sign2(_ transaction: TronSmartContractTransactionRequest, with signer: TransactionSigner, publicKey: Data) -> AnyPublisher<TronTransactionRequest2, Error> {
        let wallet = self.wallet
        
        let rawData = Data(hex: transaction.transaction.raw_data_hex)
        let hash = rawData.sha256()
        
        return Just(())
            .setFailureType(to: Error.self)
            .flatMap { [wallet] _ -> AnyPublisher<Data, Error> in
                return signer.sign(hash: hash, cardId: wallet.cardId, walletPublicKey: wallet.publicKey)
            }
            .tryMap { [weak self] signature -> TronTransactionRequest2 in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                let unmarshalledSignature = self.unmarshal(signature, hash: hash, publicKey: publicKey).hexString
                
                var newTransaction = transaction.transaction
                newTransaction.signature = [unmarshalledSignature]
                return newTransaction
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        let decimalAmount = amount.value * wallet.blockchain.decimalValue
        let intAmount = (decimalAmount.rounded() as NSDecimalNumber).uint64Value
       
        let transactionPiecesPublisher: AnyPublisher<(String, String), Error>
        
        switch amount.type {
        case .coin:
            transactionPiecesPublisher = networkService
                .createTransaction(from: wallet.address, to: destination, amount: intAmount)
                .flatMap { [weak self] request -> AnyPublisher<TronTransactionRequest, Error> in
                    guard let self = self else {
                        return .anyFail(error: WalletError.empty)
                    }
                    let signer = Self.feeSigner
                    return self.sign(request, with: signer, publicKey: signer.publicKey)
                }
                .map {
                    ($0.raw_data_hex, $0.signature?.first ?? "")
                }
                .eraseToAnyPublisher()
        case .token(let token):
            transactionPiecesPublisher = networkService
                .createTrc20Transaction(from: wallet.address, to: destination, contractAddress: token.contractAddress, amount: intAmount)
                .flatMap { [weak self] request -> AnyPublisher<TronTransactionRequest2, Error> in
                    guard let self = self else {
                        return .anyFail(error: WalletError.empty)
                    }
                    let signer = Self.feeSigner
                    return self.sign2(request, with: signer, publicKey: signer.publicKey)
                }
                .map {
                    ($0.raw_data_hex, $0.signature?.first ?? "")
                }
                .eraseToAnyPublisher()
        default:
            return .anyFail(error: WalletError.failedToGetFee)
        }
        
        let estimatedEnergyUsePublisher: AnyPublisher<Int, Error>
        switch amount.type {
        case .coin:
            estimatedEnergyUsePublisher = Just(0).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .token(let token):
            estimatedEnergyUsePublisher = networkService.tokenTransferMaxEnergyUse(contractAddress: token.contractAddress)
        default:
            return .anyFail(error: WalletError.failedToGetFee)
        }
        
        let blockchain = self.wallet.blockchain
        
        return networkService.getAccountResource(for: wallet.address)
            .zip(networkService.accountExists(address: destination), transactionPiecesPublisher, estimatedEnergyUsePublisher)
            .map { (resources, destinationExists, transactionPieces, estimatedEnergyUse) -> Amount in
                if !destinationExists {
                    return Amount(with: blockchain, value: 1.1)
                }
                
                print(resources, destinationExists, transactionPieces)
                
                let additionalDataSize = 69
                let transactionByteSize = (Data(hex: transactionPieces.0) + Data(hex: transactionPieces.1)).count + additionalDataSize
                let sunPerTransactionByte = 1000
                let transactionSizeFee = transactionByteSize * sunPerTransactionByte
                print(transactionByteSize)
                
                
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
    
    private func updateWallet(_ accountInfo: TronAccountInfo) {
        let blockchain = wallet.blockchain
        wallet.add(amount: Amount(with: blockchain, value: accountInfo.balance))
        
        for (token, tokenBalance) in accountInfo.tokenBalances {
            wallet.add(tokenValue: tokenBalance, for: token)
        }
    }
    
    private func unmarshal(_ signature: Data, hash: Data, publicKey: Data) -> Data {
        guard publicKey != Self.feeSigner.publicKey else {
            return signature + Data(0)
        }
        
        do {
            let secpSignature = try Secp256k1Signature(with: signature)
            let components = try secpSignature.unmarshal(with: publicKey, hash: hash)
            
            return components.r + components.s + components.v
        } catch {
            print(error)
            return Data()
        }
    }
}

extension TronWalletManager: ThenProcessable {
    
}


fileprivate class DummySigner: TransactionSigner {
    let privateKey: Data
    let publicKey: Data

    init() {
        let keyPair = try! Secp256k1Utils().generateKeyPair()
        let compressedPublicKey = try! Secp256k1Key(with: keyPair.publicKey).compress()
        self.publicKey = compressedPublicKey
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
