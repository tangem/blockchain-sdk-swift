//
//  Wallet.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct Wallet {
    
    // MARK: - Properties

    public let blockchain: Blockchain
    public let walletAddresses: [AddressType: PublicAddress]
    
    public internal(set) var amounts: [Amount.AmountType: Amount] = [:]
    public internal(set) var transactions: [Transaction] = []
    
    // MARK: - Calculations
    
    public var addresses: [PublicAddress] { walletAddresses.map { $0.value } }
    public var defaultAddress: PublicAddress { walletAddresses[.default]! }
    
    /// `publicKey` from default address
    public var publicKey: Wallet.PublicKey { defaultAddress.publicKey }
    
    /// Default address
    public var address: String { defaultAddress.value }

    public var isEmpty: Bool {
        return amounts.filter { $0.key != .reserve && !$0.value.isZero }.isEmpty
    }

    public var hasPendingTx: Bool {
        return !transactions.filter { $0.status == .unconfirmed }.isEmpty
    }
    
    public var pendingOutgoingTransactions: [Transaction] {
        transactions.filter { tx in
            tx.status == .unconfirmed &&
            tx.destinationAddress != .unknown &&
            addresses.contains(where: { $0.value == tx.sourceAddress })
        }
    }
    
    public var pendingIncomingTransactions: [Transaction] {
        transactions.filter { tx in
            tx.status == .unconfirmed &&
            tx.sourceAddress != .unknown &&
            addresses.contains(where: { $0.value == tx.destinationAddress })
        }
    }
    
    public var pendingBalance: Decimal {
        pendingOutgoingTransactions
            .reduce(0, { $0 + $1.amount.value + $1.fee.amount.value })
    }

    @available(*, deprecated, message: "Use xpubKeys with each address support")
    public var xpubKey: String? {
        defaultAddress.publicKey.xpubKey(isTestnet: blockchain.isTestnet)
    }
    
    public var xpubKeys: [String] {
        walletAddresses
            .compactMapValues { $0.publicKey.xpubKey(isTestnet: blockchain.isTestnet) }
            .map { $0.value }
    }
    
    @available(*, deprecated, message: "Use init(blockchain:, addresses:)")
    init(blockchain: Blockchain, addresses: [Address], publicKey: PublicKey) {
        self.blockchain = blockchain
                
        let addresses: [AddressType: PublicAddress] = addresses.reduce(into: [:]) { result, address in
            result[address.type] = PublicAddress(value: address.value, publicKey: publicKey, type: address.type)
        }
        
        assert(addresses[.default] != nil, "Addresses have to contains default address")

        self.walletAddresses = addresses
    }
    
    init(blockchain: Blockchain, addresses: [AddressType: PublicAddress]) {
        self.blockchain = blockchain
        self.walletAddresses = addresses
    }
    
    public func hasPendingTx(for amountType: Amount.AmountType) -> Bool {
        return !transactions.filter { $0.status == .unconfirmed && $0.amount.type == amountType }.isEmpty
    }
    
    /// Explore URL for specific address
    /// - Parameter address: If nil, default address will be used
    /// - Returns: URL
    public func getExploreURL(for address: String? = nil, token: Token? = nil) -> URL? {
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
    
    public mutating func add(coinValue: Decimal) {
        let coinAmount = Amount(with: blockchain, type: .coin, value: coinValue)
        add(amount: coinAmount)
    }
    
    public mutating func add(reserveValue: Decimal) {
        let reserveAmount = Amount(with: blockchain, type: .reserve, value: reserveValue)
        add(amount: reserveAmount)
    }
    
    @discardableResult
    public mutating func add(tokenValue: Decimal, for token: Token) -> Amount {
        let tokenAmount = Amount(with: token, value: tokenValue)
        add(amount: tokenAmount)
        return tokenAmount
    }
    
    public mutating func add(amount: Amount) {
        amounts[amount.type] = amount
    }
    
    // MARK: - Internal
    
    mutating func clearAmounts() {
        amounts = [:]
    }
    
    mutating func add(transaction: Transaction) {
        var tx = transaction
        tx.date = Date()
        transactions.append(tx)
    }
    
    mutating func addPendingTransaction(amount: Amount,
                                        fee: Amount,
                                        sourceAddress: String,
                                        destinationAddress: String,
                                        date: Date,
                                        changeAddress: String = .unknown,
                                        transactionHash: String,
                                        transactionParams: TransactionParams? = nil) {
        if transactions.contains(where: { $0.hash == transactionHash }) {
            return
        }
        
        if addresses.contains(where: { $0.value == sourceAddress }) &&
            addresses.contains(where: { $0.value == destinationAddress }) {
            return
        }
        
        var tx = Transaction(amount: amount,
                             fee: Fee(fee),
                             sourceAddress: sourceAddress,
                             destinationAddress: destinationAddress,
                             changeAddress: changeAddress,
                             date: date,
                             hash: transactionHash)
        tx.params = transactionParams
        transactions.append(tx)
    }
    
    mutating func addPendingTransaction(_ tx: PendingTransaction) {
        addPendingTransaction(amount: Amount(with: blockchain, value: tx.value),
                              fee: Amount(with: blockchain, value: tx.fee ?? 0),
                              sourceAddress: tx.source,
                              destinationAddress: tx.destination,
                              date: tx.date,
                              transactionHash: tx.hash,
                              transactionParams: tx.transactionParams)
    }
    
    mutating func addDummyPendingTransaction() {
        let dummyAmount = Amount.dummyCoin(for: blockchain)
        var tx = Transaction(amount: dummyAmount,
                             fee: Fee(dummyAmount),
                             sourceAddress: .unknown,
                             destinationAddress: address,
                             changeAddress: .unknown)
        tx.date = Date()
        transactions.append(tx)
    }
    
    mutating func setTransactionHistoryList(_ transactions: [Transaction]) {
        self.transactions = transactions
    }
    
    mutating func remove(token: Token) {
        amounts[.token(value: token)] = nil
    }
}
