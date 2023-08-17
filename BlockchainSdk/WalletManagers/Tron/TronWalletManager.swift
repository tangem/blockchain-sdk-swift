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
    var networkService: TronNetworkService!
    var txBuilder: TronTransactionBuilder!
    
    var currentHost: String {
        networkService.host
    }
    
    var allowsFeeSelection: Bool {
        false
    }
    
    private let feeSigner = DummySigner()
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
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
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        return signedTransactionData(amount: transaction.amount, source: wallet.address, destination: transaction.destinationAddress, signer: signer, publicKey: wallet.publicKey)
            .flatMap { [weak self] data -> AnyPublisher<TronBroadcastResponse, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return self.networkService.broadcastHex(data)
            }
            .tryMap { [weak self] broadcastResponse -> TransactionSendResult in
                guard broadcastResponse.result == true else {
                    throw WalletError.failedToSendTx
                }
                
                var submittedTransaction = transaction
                submittedTransaction.hash = broadcastResponse.txid
                self?.wallet.transactions.append(submittedTransaction)
                
                return TransactionSendResult(hash: broadcastResponse.txid)
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let energyFeePublisher = energyFee(amount: amount, destination: destination)
        
        let transactionDataPublisher = signedTransactionData(
            amount: amount,
            source: wallet.address,
            destination: destination,
            signer: feeSigner,
            publicKey: feeSigner.publicKey
        )

        let blockchain = self.wallet.blockchain

        return Publishers.Zip4(energyFeePublisher, networkService.accountExists(address: destination), transactionDataPublisher, networkService.getAccountResource(for: wallet.address))
            .map { energyFee, destinationExists, transactionData, resources -> [Fee] in
                if !destinationExists && amount.type == .coin {
                    let amount = Amount(with: blockchain, value: 1.1)
                    return [Fee(amount)]
                }
                
                let sunPerBandwidthPoint = 1000
                
                let remainingBandwidthInSun = (resources.freeNetLimit - (resources.freeNetUsed ?? 0)) * sunPerBandwidthPoint
                
                let additionalDataSize = 64
                let transactionSizeFee = sunPerBandwidthPoint * (transactionData.count + additionalDataSize)
                let consumedBandwidthFee: Int
                if transactionSizeFee <= remainingBandwidthInSun {
                    consumedBandwidthFee = 0
                } else {
                    consumedBandwidthFee = transactionSizeFee
                }
                
                let totalFee = consumedBandwidthFee + energyFee
                
                let value = Decimal(totalFee) / blockchain.decimalValue
                let amount = Amount(with: blockchain, value: value)
                return [Fee(amount)]
            }
            .eraseToAnyPublisher()
    }
    
    private func energyFee(amount: Amount, destination: String) -> AnyPublisher<Int, Error> {
        let token: Token
        switch amount.type {
        case .reserve:
            return .anyFail(error: WalletError.failedToGetFee)
        case .coin:
            return Just(0).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .token(let amountToken):
            token = amountToken
        }
        
        let addressData = TronAddressService.toByteForm(destination)?.aligned(to: 32) ?? Data()
        guard let amountData = amount.encodedAligned else {
            return .anyFail(error: WalletError.failedToGetFee)
        }
        
        let parameter = (addressData + amountData).hex
        
        let energyUsePublisher = networkService.contractEnergyUsage(
            sourceAddress: wallet.address,
            contractAddress: token.contractAddress,
            parameter: parameter
        )
        
        return Publishers.Zip(energyUsePublisher, networkService.chainParameters())
            .map { energyUse, chainParameters in
                // Contract's energy fee changes every maintenance period (6 hours) and
                // since we don't know what period the transaction is going to be executed in
                // we increase the fee just in case by 20%
                let sunPerEnergyUnit = chainParameters.sunPerEnergyUnit
                let energyFee = Double(energyUse * sunPerEnergyUnit)
                
                let dynamicEnergyIncreaseFactorPresicion = 10_000
                let dynamicEnergyIncreaseFactor = Double(chainParameters.dynamicEnergyIncreaseFactor) / Double(dynamicEnergyIncreaseFactorPresicion)
                let conservativeEnergyFee = Int(energyFee * (1 + dynamicEnergyIncreaseFactor))
                
                return conservativeEnergyFee
            }
            .eraseToAnyPublisher()
    }
    
    private func signedTransactionData(amount: Amount, source: String, destination: String, signer: TransactionSigner, publicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        return networkService.getNowBlock()
            .tryMap { [weak self] block -> Protocol_Transaction.raw in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                return try self.txBuilder.buildForSign(amount: amount, source: source, destination: destination, block: block)
            }
            .flatMap { [weak self] transactionRaw -> AnyPublisher<Data, Error> in
                guard let self = self else {
                    return .anyFail(error: WalletError.empty)
                }
                
                return Just(())
                    .setFailureType(to: Error.self)
                    .flatMap { [weak self] _ -> AnyPublisher<Data, Error> in
                        guard let self = self else {
                            return .anyFail(error: WalletError.empty)
                        }
                        
                        return self.sign(transactionRaw, with: signer, publicKey: publicKey)
                    }
                    .tryMap { [weak self] signature -> Protocol_Transaction in
                        guard let self = self else {
                            throw WalletError.empty
                        }
                        
                        return self.txBuilder.buildForSend(rawData: transactionRaw, signature: signature)
                    }
                    .tryMap {
                        try $0.serializedData()
                    }
                    .eraseToAnyPublisher()
            }
            
            .eraseToAnyPublisher()
    }
    
    private func sign(_ transactionRaw: Protocol_Transaction.raw, with signer: TransactionSigner, publicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .tryMap {
                try transactionRaw.serializedData().sha256()
            }
            .flatMap { hash -> AnyPublisher<Data, Error> in
                Just(hash)
                    .setFailureType(to: Error.self)
                    .flatMap {
                        signer.sign(hash: $0, walletPublicKey: publicKey)
                    }
                    .tryMap { [weak self] signature -> Data in
                        guard let self = self else {
                            throw WalletError.empty
                        }
                        
                        return self.unmarshal(signature, hash: hash, publicKey: publicKey)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func updateWallet(_ accountInfo: TronAccountInfo) {
        wallet.add(amount: Amount(with: wallet.blockchain, value: accountInfo.balance))
        
        for (token, balance) in accountInfo.tokenBalances {
            wallet.add(tokenValue: balance, for: token)
        }
        
        for (index, transaction) in wallet.transactions.enumerated() {
            if let hash = transaction.hash, accountInfo.confirmedTransactionIDs.contains(hash) {
                wallet.transactions[index].status = .confirmed
            }
        }
    }
    
    private func unmarshal(_ signatureData: Data, hash: Data, publicKey: Wallet.PublicKey) -> Data {
        guard publicKey != feeSigner.publicKey else {
            return signatureData + Data(0)
        }
        
        do {
            let signature = try Secp256k1Signature(with: signatureData)
            let unmarshalledSignature = try signature.unmarshal(with: publicKey.blockchainKey, hash: hash).data
            
            return unmarshalledSignature
        } catch {
            Log.error(error)
            return Data()
        }
    }
}

extension TronWalletManager: ThenProcessable {}


fileprivate class DummySigner: TransactionSigner {
    let privateKey: Data
    let publicKey: Wallet.PublicKey
    
    init() {
        let keyPair = try! Secp256k1Utils().generateKeyPair()
        let compressedPublicKey = try! Secp256k1Key(with: keyPair.publicKey).compress()
        self.publicKey = Wallet.PublicKey(seedKey: compressedPublicKey, derivationType: .none)
        self.privateKey = keyPair.privateKey
    }
        
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        do {
            let signature = try Secp256k1Utils().sign(hash, with: privateKey)
            return Just(signature)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
    
    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        fatalError()
    }
}
