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
    
    public private(set) var coinAmount: Amount? = nil
    public private(set) var reserveAmount: Amount? = nil
    
    public var tokens: [String:Token] = [:]
    public var transactions: [Transaction] = []
    
    public var address: String { addresses.first {$0.label.isDefault}!.value}
    
    public var isEmpty: Bool {
        guard let coinAmount = coinAmount, coinAmount.value == 0,
        tokens.values.filter ({ !$0.isEmpty }).count == 0 else {
            return false
        }
        
        return true
    }
    
    public var hasPendingTx: Bool {
        return transactions.filter { $0.status == .unconfirmed }.count > 0
    }
    
    internal init(blockchain: Blockchain, addresses: [Address], tokens: [TokenData] = []) {
        self.blockchain = blockchain
        self.addresses = addresses
        addTokens(tokens)
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
        coinAmount = nil
        reserveAmount = nil
    }
    
    mutating func set(coinValue: Decimal) {
        coinAmount = Amount(with: blockchain, address: address, type: .coin, value: coinValue)
    }
    
    mutating func set(reserveValue: Decimal) {
        reserveAmount = Amount(with: blockchain, address: address, type: .reserve, value: reserveValue)
    }
    
    mutating func set(tokenValue: Decimal, for currencySymbol: String) {
        tokens[currencySymbol]?.set(amountValue: tokenValue)
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
    
    mutating func addToken(_ tokenData: TokenData) {
        let displayName = blockchain.tokenDisplayName
        let token = Token(with: tokenData, displayName: displayName)
        tokens[token.currencySymbol] = token
    }
    
    mutating func addTokens(_ tokensData: [TokenData]) {
        tokensData.forEach { self.addToken($0) }
    }
}

extension Wallet: AmountStringConvertible {
    public var amountDescription: String {
        return coinAmount?.description ?? "-"
    }
}
