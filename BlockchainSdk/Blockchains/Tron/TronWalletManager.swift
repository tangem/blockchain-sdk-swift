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
        cancellable = networkService.accountInfo(
            for: wallet.address,
            tokens: cardTokens,
            transactionIDs: wallet.pendingTransactions.map { $0.hash }
        )
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

        let blockchain = wallet.blockchain

        let dummyTransaction = Transaction(
            amount: amount,
            fee: Fee(.zeroCoin(for: blockchain)),
            sourceAddress: wallet.address,
            destinationAddress: destination,
            changeAddress: wallet.address)

        let transactionDataPublisher = signedTransactionData(
            transaction: dummyTransaction,
            signer: feeSigner,
            publicKey: feeSigner.publicKey
        )

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

        let energyUsagePublisher = Result {
            try txBuilder.buildContractEnergyUsageData(amount: amount, destinationAddress: destination)
        }
            .publisher
            .withWeakCaptureOf(self)
            .flatMap { manager, energyUsageData in
                manager.networkService.contractEnergyUsage(
                    sourceAddress: manager.wallet.address,
                    contractAddress: contractAddress,
                    contractEnergyUsageData: energyUsageData
                )
            }

        return energyUsagePublisher.zip(networkService.chainParameters())
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
                try manager.txBuilder.buildForSign(transaction: transaction, block: block)
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
        publicKey = Wallet.PublicKey(seedKey: compressedPublicKey, derivationType: .none)
        privateKey = keyPair.privateKey
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

// MARK: - TronNetworkprovider

extension TronWalletManager: TronNetworkProvider {
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, any Error> {
        let allowanceDataPublisher = Result {
            try txBuilder.buildForAllowance(owner: owner, spender: spender)
        }.publisher

        return allowanceDataPublisher
            .withWeakCaptureOf(self)
            .flatMap { manager, allowanceData in
                manager.networkService.getAllowance(owner: owner, contractAddress: contractAddress, allowanceData: allowanceData)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - TronTransactionDataBuilder

extension TronWalletManager: TronTransactionDataBuilder {
    func buildForApprove(spender: String, amount: Amount) throws -> Data {
        return try txBuilder.buildForApprove(spender: spender, amount: amount)
    }
}

// MARK: - StakeKitTransactionSender, StakeKitTransactionSenderProvider

extension TronWalletManager: StakeKitTransactionSender, StakeKitTransactionSenderProvider {
    typealias RawTransaction = Data

    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data {
        try TronStakeKitTransactionHelper().prepareForSign(transaction.unsignedData).hash
    }

    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction {
        let rawData = try TronStakeKitTransactionHelper().prepareForSign(transaction.unsignedData).rawData
        let unmarshalled = unmarshal(signature.signature, hash: signature.hash, publicKey: wallet.publicKey)
        return try txBuilder.buildForSend(rawData: rawData, signature: unmarshalled)
    }

    func broadcast(transaction: StakeKitTransaction, rawTransaction: RawTransaction) async throws -> String {
        try await networkService.broadcastHex(rawTransaction).async().txid
    }
}
//
//extension TronWalletManager: StakeKitTransactionSender {
//    func sendStakeKit(_ action: StakeKitTransactionAction, signer: any TransactionSigner) async throws -> [TransactionSendResult] {
//        guard case .multiple(let transactions) = action else {
//            throw BlockchainSdkError.notImplemented
//        }
//
//        let prepared = try transactions.map {
//            try TronStakeKitTransactionHelper().prepareForSign($0.unsignedData)
//        }
//
//        let hashes = prepared.map { $0.hash }
//        let signatures = try await signer.sign(hashes: hashes, walletPublicKey: wallet.publicKey).async()
//
//        let readyToSend = try zip(prepared, signatures).map { (input, signature) in
//            let unmarshalledSignature = unmarshal(signature, hash: input.hash, publicKey: wallet.publicKey)
//            return try txBuilder.buildForSend(rawData: input.rawData, signature: unmarshalledSignature)
//        }
//
//        var results: [TransactionSendResult] = []
//
//        for (transaction, data) in zip(transactions, readyToSend) {
//            do {
//                let result = try await networkService.broadcastHex(data).async()
//                try await Task.sleep(1 * NSEC_PER_SEC)
//
//                let hash = result.txid
//                let mapper = PendingTransactionRecordMapper()
//                let record = mapper.mapToPendingTransactionRecord(
//                    stakeKitTransaction: transaction,
//                    source: wallet.defaultAddress.value,
//                    hash: hash
//                )
//                wallet.addPendingTransaction(record)
//                results.append(TransactionSendResult(hash: hash))
//            } catch {
//                throw SendTxErrorFactory().make(error: error, with: data.hexString)
//            }
//        }
//
//        return results
//    }

//    func sendStakeKit(transactions: [StakeKitTransaction], signer: TransactionSigner) -> AnyPublisher<[TransactionSendResult], SendTxError> {
//
//        let presignedInputsPublisher = Result {
//            try transactions.map {
//                try TronStakeKitTransactionHelper().prepareForSign($0.unsignedData)
//            }
//        }.publisher
//
//        let readyToSendTransactionsPublisher = presignedInputsPublisher
//            .withWeakCaptureOf(self)
//            .flatMap { manager, inputs -> AnyPublisher<[Data], Error> in
//                signer
//                    .sign(hashes: inputs.map { $0.hash }, walletPublicKey: manager.wallet.publicKey)
//                    .tryMap { signatures -> [Data] in
//                        try zip(inputs, signatures).map { (input, signature) in
//                            let unmarshalledSignature = manager.unmarshal(
//                                signature,
//                                hash: input.hash,
//                                publicKey: manager.wallet.publicKey
//                            )
//
//                            return try manager.txBuilder.buildForSend(
//                                rawData: input.rawData,
//                                signature: unmarshalledSignature
//                            )
//                        }
//                    }
//                    .eraseToAnyPublisher()
//            }
//
//        let sentTransactionsPublisher = readyToSendTransactionsPublisher
//            .flatMap { [weak self] transactionsData -> AnyPublisher<[TronBroadcastResponse], Error> in
//                guard let self else {
//                    return .anyFail(error: WalletError.empty)
//                }
//
//                let sendPublishers = transactionsData
//                    .map { data in
//                        self.networkService
//                            .broadcastHex(data)
//                            .mapSendError(tx: data.hexString)
//                            .eraseToAnyPublisher()
//                    }
//
//                return Publishers.Sequence(sequence: sendPublishers)
//                    .flatMap(maxPublishers: .max(1)) { $0 }
//                    .collect()
//                    .eraseToAnyPublisher()
//            }
//
//        return sentTransactionsPublisher
//            .withWeakCaptureOf(self)
//            .tryMap { manager, broadcastResponses -> [TransactionSendResult] in
//                guard broadcastResponses.count == transactions.count,
//                      broadcastResponses.allSatisfy({ $0.result }) else {
//                    throw WalletError.failedToSendTx
//                }
//
//                var results: [TransactionSendResult] = []
//
//                for (transaction, broadcastResponse) in zip(transactions, broadcastResponses) {
//                    let hash = broadcastResponse.txid
//                    let mapper = PendingTransactionRecordMapper()
//                    let record = mapper.mapToPendingTransactionRecord(stakeKitTransaction: transaction, hash: hash)
//                    manager.wallet.addPendingTransaction(record)
//                    results.append(TransactionSendResult(hash: hash))
//                }
//
//                return results
//            }
//            .eraseSendError()
//            .eraseToAnyPublisher()
//    }
//
//    func sendStakeKit(transaction: StakeKitTransaction, signer: any TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
//        return .anyFail(error: .init(error: BlockchainSdkError.notImplemented))
//    }
//}

