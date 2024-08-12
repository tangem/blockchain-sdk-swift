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
        let encodedAddressPublisher =  Result {
            try TronUtils().convertAddressToHEX(wallet.address)
        }.publisher

        cancellable = encodedAddressPublisher
            .withWeakCaptureOf(self)
            .flatMap{ manager, encodedAddress in
                manager.networkService.accountInfo(
                    for: manager.wallet.address,
                    tokens: manager.cardTokens,
                    transactionIDs: manager.wallet.pendingTransactions.map { $0.hash },
                    encodedAddress: encodedAddress
                )
            }
            .sink { [weak self] in
                switch $0 {
                case .failure(let error):
                    self?.wallet.clearAmounts()
                    completion(.failure(error))
                case .finished:
                    completion(.success(()))
                }
            } receiveValue: { [weak self] accountInfo in
                self?.updateWallet(accountInfo)
            }
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        return signedTransactionData(
            transaction: transaction,
            signer: signer,
            publicKey: wallet.publicKey
        )
        .withWeakCaptureOf(self)
        .flatMap { manager, data  in
            manager.networkService
                .broadcastHex(data)
                .mapSendError(tx: data.hexString)
        }
        .withWeakCaptureOf(self)
        .tryMap { manager, broadcastResponse -> TransactionSendResult in
            guard broadcastResponse.result == true else {
                throw WalletError.failedToSendTx
            }

            let hash = broadcastResponse.txid
            let mapper = PendingTransactionRecordMapper()
            let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
            manager.wallet.addPendingTransaction(record)
            return TransactionSendResult(hash: hash)
        }
        .eraseSendError()
        .eraseToAnyPublisher()
    }

    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        let energyFeePublisher = energyFee(amount: amount, destination: destination)

        let dummyTransaction = Transaction(
            amount: amount,
            fee: Fee(.zeroCoin(for: .tron(testnet: false))),
            sourceAddress: wallet.address,
            destinationAddress: destination,
            changeAddress: wallet.address)

        let transactionDataPublisher = signedTransactionData(
            transaction: dummyTransaction,
            signer: feeSigner,
            publicKey: feeSigner.publicKey
        )

        let blockchain = wallet.blockchain

        return Publishers.Zip4(
            energyFeePublisher,
            networkService.accountExists(address: destination),
            transactionDataPublisher,
            networkService.getAccountResource(for: wallet.address)
        )
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
        guard let contractAddress = amount.type.token?.contractAddress else {
            return .justWithError(output: 0)
        }

        let energyUsePublisher = Result {
            try txBuilder.buildContractEnergyUsageParameter(amount: amount, destinationAddress: destination)
        }
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { manager, parameter in
                manager.networkService.contractEnergyUsage(
                    sourceAddress: manager.wallet.address,
                    contractAddress: contractAddress,
                    parameter: parameter
                )
            }

        return energyUsePublisher.zip(networkService.chainParameters())
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
    
    private func signedTransactionData(transaction: Transaction, signer: TransactionSigner, publicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        networkService.getNowBlock()
            .withWeakCaptureOf(self)
            .tryMap { manager, block in
                try self.txBuilder.buildForSign(transaction: transaction, block: block)
            }
            .flatMap { presignedInput in
                signer.sign(hash: presignedInput.hash, walletPublicKey: publicKey)
                    .withWeakCaptureOf(self)
                    .tryMap { manager, signature in
                        let unmarshalledSignature = manager.unmarshal(signature, hash: presignedInput.hash, publicKey: publicKey)
                        return try manager.txBuilder.buildForSend(rawData: presignedInput.rawData, signature: unmarshalledSignature)
                    }
            }
            .eraseToAnyPublisher()
    }

    private func updateWallet(_ accountInfo: TronAccountInfo) {
        wallet.add(amount: Amount(with: wallet.blockchain, value: accountInfo.balance))

        for (token, balance) in accountInfo.tokenBalances {
            wallet.add(tokenValue: balance, for: token)
        }

        wallet.removePendingTransaction { hash in
            accountInfo.confirmedTransactionIDs.contains(hash)
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
