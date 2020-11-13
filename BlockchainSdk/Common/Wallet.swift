//
//  Wallet.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public struct Wallet {
    public let blockchain: Blockchain
    public let addresses: [Address]
    
    public var amounts: [Amount.AmountType:Amount] = [:]
    public var transactions: [Transaction] = []
    
    public var address: String { addresses.first {$0.label.isDefault}!.value}
    
    public var isEmpty: Bool {
        return amounts.values.filter ({ !$0.isEmpty }).count == 0
    }

    public var hasPendingTx: Bool {
        return transactions.filter { $0.status == .unconfirmed }.count > 0
    }
    
    internal init(blockchain: Blockchain, addresses: [Address], tokens: [Token]) {
        self.blockchain = blockchain
        self.addresses = addresses
        self.amounts[.coin] = Amount(with: blockchain, address: address)
    
        let tokenAmounts = tokens.map { Amount(with: $0) }
        for tokenAmount in tokenAmounts {
            self.amounts[tokenAmount.type] = tokenAmount
        }
    }
    
    /// Explore URL for specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: URL
    public func getExploreURL(for address: String? = nil, token: Token? = nil) -> URL {
        let address = address ?? self.address
        return blockchain.getExploreURL(from: address, tokenContractAddress: token?.contractAddress)
    }
    
    /// Share string for specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: String to share
    public func getShareString(for address: String? = nil) -> String {
        let address = address ?? self.address
        return blockchain.getShareString(from: address)
    }
    
    mutating func clearAmounts() {
        amounts.forEach { amounts[$0.key]?.clear() }
    }
    
    mutating func add(coinValue: Decimal) {
        amounts[.coin]?.value = coinValue
    }
    
    mutating func add(reserveValue: Decimal) {
        amounts[.reserve] = Amount(with: blockchain, address: address, type: .reserve, value: reserveValue)
    }
    
    mutating func add(tokenValue: Decimal, for token: Token) {
        let amount = Amount(with: token, value: tokenValue)
        amounts[amount.type] = amount
    }
    
    mutating func add(transaction: Transaction) {
        var tx = transaction
        tx.date = Date()
        transactions.append(tx)
    }
    
    mutating func addPendingTransaction() {
        let dummyAmount = Amount(with: blockchain, address: "unknown", type: .coin, value: 0)
        var tx = Transaction(amount: dummyAmount, fee: dummyAmount, sourceAddress: "unknown", destinationAddress: address)
        tx.date = Date()
        transactions.append(tx)
    }
}
