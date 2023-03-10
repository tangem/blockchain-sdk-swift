//
//  EthereumWalletManagerProtocols.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import Combine
import TangemSdk
import Moya
import web3swift

@available(iOS 13.0, *)
public protocol EthereumGasLoader: AnyObject {
    func getGasPrice() -> AnyPublisher<BigUInt, Error>
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error>
}

@available(iOS 13.0, *)
public protocol EthereumTransactionSigner: AnyObject {
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error>
}

@available(iOS 13.0, *)
public protocol EthereumTransactionProcessor {
    var initialNonce: Int { get }
    func buildForSign(_ transaction: Transaction) -> AnyPublisher<CompiledEthereumTransaction, Error>
    func buildForSend(_ transaction: SignedEthereumTransaction) -> AnyPublisher<String, Error>
    func getFee(to: String, data: String?, amount: Amount?) -> AnyPublisher<[Amount], Error>
    func send(_ transaction: SignedEthereumTransaction) -> AnyPublisher<String, Error>
    func getAllowance(from: String, to: String, contractAddress: String) -> AnyPublisher<Decimal, Error>
}

@available(iOS 13.0, *)
public protocol EthereumNetworkProvider {
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error>
    func getTxCount(_ address: String) -> AnyPublisher<Int, Error> 
}

public struct CompiledEthereumTransaction {
    public let transaction: EthereumTransaction
    public let hash: Data
}

public struct SignedEthereumTransaction {
    public let transaction: EthereumTransaction
    public let hash: Data
    public let signature: Data
    
    public init(compiledTransaction: CompiledEthereumTransaction, signature: Data) {
        self.transaction = compiledTransaction.transaction
        self.hash = compiledTransaction.hash
        self.signature = signature
    }
}
