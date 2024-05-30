//
//  TONWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import WalletCore
import TonSwift
import BigInt

final class TONWalletManager: BaseManager, WalletManager {
    
    // MARK: - Properties
    
    var currentHost: String { networkService.host }
    
    // MARK: - Private Properties
    
    private let networkService: TONNetworkService
    private let txBuilder: TONTransactionBuilder
    private var isAvailable: Bool = true
    
    // MARK: - Init
    
    init(wallet: Wallet, networkService: TONNetworkService) throws {
        self.networkService = networkService
        self.txBuilder = .init(wallet: wallet)
        super.init(wallet: wallet)
    }
    
    // MARK: - Implementation
    
    override func update(completion: @escaping (Result<Void, Error>) -> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address, tokens: cardTokens)
            .sink(
                receiveCompletion: { [weak self] completionSubscription in
                    if case let .failure(error) = completionSubscription {
                        self?.wallet.clearAmounts()
                        self?.isAvailable = false
                        completion(.failure(error))
                    }
                },
                receiveValue: { [weak self] info in
                    self?.update(with: info, completion: completion)
                }
            )
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError> {
        Just(())
            .receive(on: DispatchQueue.global())
            .tryMap { [weak self] _ -> String in
                guard let self = self else {
                    throw WalletError.failedToBuildTx
                }
                
//                return try buildJettonTransaction(transaction)
                
                let params = transaction.params as? TONTransactionParams
                
                let input = try self.txBuilder.buildForSign(
                    amount: transaction.amount,
                    destination: transaction.destinationAddress,
                    params: params
                )
                return try self.buildTransaction(input: input, with: signer)
            }
            .flatMap { [weak self] message -> AnyPublisher<String, Error> in
                guard let self = self else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }
                
                return self.networkService
                    .send(message: message)
                    .mapSendError(tx: message)
                    .eraseToAnyPublisher()
            }
            .map { [weak self] hash in
                let mapper = PendingTransactionRecordMapper()
                let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                self?.wallet.addPendingTransaction(record)
                return TransactionSendResult(hash: hash)
            }
            .eraseSendError()
            .eraseToAnyPublisher()
    }
    
    func buildJettonTransaction(_ transaction: Transaction) throws -> String {
        guard let decimal = transaction.amount.type.token?.decimalValue,
              let contractAddress = transaction.contractAddress,
              let jettonAddress = try? TonSwift.Address.parse("kQAg-9HHel0pd8DBTNofkXYFcfIS_FsVPHNaTYD6HqWAk56O"),
              let toAddress = try? TonSwift.Address.parse("0QDNlCpcoNcMTfl3_Rybj-gPeFTgg-c8fauyDqVp4r6eS-UP"),
              let fromAddress = try? TonSwift.Address.parse("0QATODhcR-gw4CAnk7vmjOXEGzpN2yek37BDp9O_biB51SoO"),
              let jettonTransferMessage = try? JettonTransferMessage.internalMessage(
                jettonAddress: jettonAddress,
                amount: BigInt((transaction.amount.value * decimal).uint64Value),
                bounce: false,
                to: toAddress, from: fromAddress
              ) else { return "" }
        
        var builder = Builder()
//        
//        let data = JettonTransferData(queryId: 0, amount: BigInt((transaction.amount.value * decimal).uint64Value).magnitude, toAddress: toAddress, responseAddress: fromAddress, forwardAmount: BigUInt(stringLiteral: "1").magnitude, forwardPayload: nil)
//        
        try builder.store(uint: OpCodes.JETTON_TRANSFER, bits: 32)
        try builder.store(uint: 0, bits: 64)
        try builder.store(coins: Coins((transaction.amount.value * decimal).uint64Value))
        try builder.store(toAddress)
        try builder.store(fromAddress)
        try builder.store(bit: false)
        try builder.store(coins: Coins(0))
        try builder.store(coins: Coins(0))
        try builder.store(uint: 64, bits: 0)
        try builder.store(uint: 32, bits: 0)
        try builder.storeMaybe(ref: Cell?.none)
        

        try? jettonTransferMessage.storeTo(builder: builder)
        return (try? builder.endCell().toBoc().base64EncodedString()) ?? ""
    }
        

    func buildTransaction(input: TheOpenNetworkSigningInput, with signer: TransactionSigner? = nil) throws -> String {
        let output: TheOpenNetworkSigningOutput
        
        if let signer = signer {
            guard let publicKey = PublicKey(tangemPublicKey: self.wallet.publicKey.blockchainKey, publicKeyType: CoinType.ton.publicKeyType) else {
                throw WalletError.failedToBuildTx
            }
            
            let coreSigner = WalletCoreSigner(
                sdkSigner: signer,
                blockchainKey: publicKey.data,
                walletPublicKey: self.wallet.publicKey,
                curve: wallet.blockchain.curve
            )
            output = try AnySigner.signExternally(input: input, coin: .ton, signer: coreSigner)
        } else {
            output = AnySigner.sign(input: input, coin: .ton)
        }
        
        return try self.txBuilder.buildForSend(output: output)
    }
}

// MARK: - TransactionFeeProvider

extension TONWalletManager: TransactionFeeProvider {
    var allowsFeeSelection: Bool { false }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return Just(())
            .tryMap { [weak self] _ -> String in
                guard let self = self else {
                    throw WalletError.failedToBuildTx
                }
                
                let input = try self.txBuilder.buildForSign(amount: amount, destination: destination)
                return try self.buildTransaction(input: input)
            }
            .flatMap { [weak self] message -> AnyPublisher<[Fee], Error> in
                guard let self = self else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }
                
                return self.networkService.getFee(address: self.wallet.address, message: message)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private Implementation

private extension TONWalletManager {
    
    private func update(with info: TONWalletInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        if info.sequenceNumber != txBuilder.sequenceNumber {
            wallet.clearPendingTransaction()
        }
        
        wallet.add(coinValue: info.balance)
        
        for (token, balance) in info.tokenBalances {
            wallet.add(tokenValue: balance, for: token)
        }
        
        txBuilder.sequenceNumber = info.sequenceNumber
        isAvailable = info.isAvailable
        completion(.success(()))
    }
}
