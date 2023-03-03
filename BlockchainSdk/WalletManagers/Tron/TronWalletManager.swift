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
import WalletCore

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
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        let walletCoreSigner = WalletCoreSigner(sdkSigner: signer, walletPublicKey: self.wallet.publicKey)
        
        return signedTransactionData(amount: transaction.amount, source: wallet.address, destination: transaction.destinationAddress, signer: walletCoreSigner, publicKey: wallet.publicKey)
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

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        let maxEnergyUsePublisher: AnyPublisher<Int, Error>
        
        switch amount.type {
        case .reserve:
            return .anyFail(error: WalletError.failedToGetFee)
        case .coin:
            maxEnergyUsePublisher = Just(0).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .token(let token):
            maxEnergyUsePublisher = networkService.tokenTransferMaxEnergyUse(contractAddress: token.contractAddress)
        }
        
        let transactionDataPublisher = signedTransactionData(
            amount: amount,
            source: wallet.address,
            destination: destination,
            signer: feeSigner,
            publicKey: feeSigner.walletPublicKey
        )

        let blockchain = self.wallet.blockchain

        return networkService.getAccountResource(for: wallet.address)
            .zip(networkService.accountExists(address: destination), transactionDataPublisher, maxEnergyUsePublisher)
            .map { (resources, destinationExists, transactionData, maxEnergyUse) -> Amount in
                if !destinationExists && amount.type == .coin {
                    return Amount(with: blockchain, value: 1.1)
                }

                let sunPerBandwidthPoint = 1000

                let additionalDataSize = 64
                let transactionSizeFee = sunPerBandwidthPoint * (transactionData.count + additionalDataSize)

                let sunPerEnergyUnit = 280
                let maxEnergyFee = maxEnergyUse * sunPerEnergyUnit

                let totalFee = transactionSizeFee + maxEnergyFee

                let remainingBandwidthInSun = (resources.freeNetLimit - (resources.freeNetUsed ?? 0)) * sunPerBandwidthPoint

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
    
    private func signedTransactionData(amount: Amount, source: String, destination: String, signer: Signer, publicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        return networkService.getNowBlock()
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] block -> Data in
                guard let self = self else {
                    throw WalletError.empty
                }
                
                let input = try self.txBuilder.buildforSign(amount: amount, source: source, destination: destination, block: block)
                
                var output: TronSigningOutput = AnySigner.signExternally(input: input, coin: .tron, signer: signer)
                
                if let error = signer.error {
                    throw error
                }
                
                output.signature = self.unmarshal(output.signature, hash: output.id, publicKey: publicKey)
                
                return try self.txBuilder.buildForSend(input: input, output: output)
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
        guard publicKey != feeSigner.walletPublicKey else {
            return signatureData + Data(0)
        }
        
        do {
            let signature = try Secp256k1Signature(with: signatureData)
            let components = try signature.unmarshal(with: publicKey.blockchainKey, hash: hash)
            
            return components.r + components.s + components.v
        } catch {
            print(error)
            return Data()
        }
    }
}

extension TronWalletManager: ThenProcessable {}


fileprivate class DummySigner: Signer {
    let walletPublicKey: Wallet.PublicKey
    
    var publicKey: Data {
        walletPublicKey.blockchainKey
    }
    
    private(set) var error: Error?
    private let privateKey: Data
    
    init() {
        let keyPair = try! Secp256k1Utils().generateKeyPair()
        let compressedPublicKey = try! Secp256k1Key(with: keyPair.publicKey).compress()
        self.walletPublicKey = Wallet.PublicKey(seedKey: compressedPublicKey, derivedKey: nil, derivationPath: nil)
        self.privateKey = keyPair.privateKey
    }
    
    func sign(_ data: Data) -> Data {
        do {
            return try Secp256k1Utils().sign(data, with: privateKey)
        } catch {
            print("Failed to sign transaction with dummy signer: \(error)")
            self.error = error
            return Data()
        }
    }
    
    func sign(_ data: [Data]) -> [Data] {
        fatalError()
    }
}
