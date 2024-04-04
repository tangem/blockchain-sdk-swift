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

public protocol EthereumTransactionSigner: AnyObject {
    func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error>
}

public protocol EthereumTransactionDataBuilder {
    func buildForTokenTransfer(destination: String, amount: Amount) -> Data
    func buildForApprove(spender: String, amount: Decimal) -> Data
}

public protocol EthereumNetworkProvider {
    func getFee(destination: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error>
    func getGasPrice() -> AnyPublisher<BigUInt, Error>
    func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error>
    
    func getAllowance(owner: String, spender: String, contractAddress: String) -> AnyPublisher<Decimal, Error>
    func getBalance(_ address: String) -> AnyPublisher<Decimal, Error>
    func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token: Decimal], Error>
    func getTxCount(_ address: String) -> AnyPublisher<Int, Error>
    func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error>
    
    func send(_ transaction: SignedEthereumTransaction) -> AnyPublisher<String, Error>
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
