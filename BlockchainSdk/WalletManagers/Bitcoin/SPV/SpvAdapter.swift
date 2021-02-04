//
//  SpvAdapter.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 27/01/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCoreSPV
import Combine

public class SpvAdapter: SpvBaseAdapter, BitcoinCoreDelegate {
    var bitcoinKit: BitcoinSPVKit!

    public init(networkType: BitcoinSPVKit.NetworkType, walletPublicKey: Data, compressedWalletPublicKey: Data, bip: Bip = .bip84, syncCheckpoint: Checkpoint?, syncMode: BitcoinCore.SyncMode, logger: Logger) {
        let key = PublicKeySelector.selectKey(pubKey: walletPublicKey, compressedPubKey: compressedWalletPublicKey, bip: bip)
        bitcoinKit = try! BitcoinSPVKit(publicKey: key,
                                        bip: bip,
                                        walletId: key.asHexString(),
                                        syncMode: syncMode,
                                        networkType: networkType,
                                        syncCheckpoint: syncCheckpoint,
                                        confirmationsThreshold: 1,
                                        logger: logger)
        
        super.init(name: "Bitcoin", coinCode: "BTC", abstractKit: bitcoinKit)
        bitcoinKit.delegate = self
    }

    class func clear() {
        try? BitcoinSPVKit.clear()
    }
}
public extension SpvAdapter {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        transactionsSignal.notify()
    }

    func transactionsDeleted(hashes: [String]) {
        transactionsSignal.notify()
    }

    func balanceUpdated(balance: BalanceInfo) {
        balanceSignal.notify()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockSignal.notify()
    }

    func kitStateUpdated(state: BitcoinCore.KitState) {
        syncStateSignal.notify()
    }

}

public class SpvBaseAdapter {
    var feeRate: Int { 3 }
    private let coinRate: Decimal = pow(10, 8)

    public let name: String
    public let coinCode: String

    private let abstractKit: AbstractKit

    let lastBlockSignal = Signal()
    let syncStateSignal = Signal()
    let balanceSignal = Signal()
    let transactionsSignal = Signal()

    init(name: String, coinCode: String, abstractKit: AbstractKit) {
        self.name = name
        self.coinCode = coinCode
        self.abstractKit = abstractKit
    }

    func transactionRecord(fromTransaction transaction: TransactionInfo) -> TransactionRecord {
        var myInputsTotalValue: Int = 0
        var myOutputsTotalValue: Int = 0
        var myChangeOutputsTotalValue: Int = 0
        var outputsTotalValue: Int = 0
        var allInputsMine = true

//        var lockInfo: (lockedUntil: Date, originalAddress: String)?
        var type: SpvTransactionType
        var from = [SpvTransactionInputOutput]()
        var to = [SpvTransactionInputOutput]()
//        var anyNotMineFromAddress: String?
//        var anyNotMineToAddress: String?

        for input in transaction.inputs {
            if input.mine {
                if let value = input.value {
                    myInputsTotalValue += value
                }
            } else {
                allInputsMine = false
            }

            from.append(SpvTransactionInputOutput(mine: input.mine, address: input.address, value: input.value, changeOutput: false))

//            if anyNotMineFromAddress == nil, let address = input.address {
//                anyNotMineFromAddress = input.address
//            }
        }

        for output in transaction.outputs {
            guard output.value > 0 else {
                continue
            }
            
            outputsTotalValue += output.value

            if output.mine {
                myOutputsTotalValue += output.value
                if output.changeOutput {
                    myChangeOutputsTotalValue += output.value
                }
            }

            to.append(SpvTransactionInputOutput(mine: output.mine, address: output.address, value: output.value, changeOutput: output.changeOutput))

//            if let pluginId = output.pluginId, pluginId == HodlerPlugin.id,
//               let hodlerOutputData = output.pluginData as? HodlerOutputData,
//               let approximateUnlockTime = hodlerOutputData.approximateUnlockTime {
//
//                lockInfo = (lockedUntil: Date(timeIntervalSince1970: Double(approximateUnlockTime)), originalAddress: hodlerOutputData.addressString)
//            }
//            if anyNotMineToAddress == nil, let address = output.address {
//                anyNotMineToAddress = output.address
//            }
        }

        var amount = myOutputsTotalValue - myInputsTotalValue

        if allInputsMine, let fee = transaction.fee {
            amount += fee
        }

        if amount > 0 {
            type = .incoming
        } else if amount < 0 {
            type = .outgoing
        } else {
            type = .sentToSelf(enteredAmount: Decimal(myOutputsTotalValue - myChangeOutputsTotalValue) / coinRate)
        }

//        let from = type == .incoming ? anyNotMineFromAddress : nil
//        let to = type == .outgoing ? anyNotMineToAddress : nil

        return TransactionRecord(
                uid: transaction.uid,
                transactionHash: transaction.transactionHash,
                transactionIndex: transaction.transactionIndex,
                interTransactionIndex: 0,
                status: SpvTransactionStatus(rawValue: transaction.status.rawValue) ?? SpvTransactionStatus.new,
                type: type,
                blockHeight: transaction.blockHeight,
                amount: Decimal(abs(amount)) / coinRate,
                fee: transaction.fee.map { Decimal($0) / coinRate },
                date: Date(timeIntervalSince1970: Double(transaction.timestamp)),
                from: from,
                to: to,
                conflictingHash: transaction.conflictingHash
        )
    }

    private func convertToSatoshi(value: Decimal) -> Int {
        let coinValue: Decimal = value * coinRate

        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return NSDecimalNumber(decimal: coinValue).rounding(accordingToBehavior: handler).intValue
    }

    public func transactionsSingle(fromUid: String?, limit: Int) -> AnyPublisher<[TransactionRecord], Error> {
        abstractKit.transactions(fromUid: fromUid, limit: limit)
            .map {  [weak self] transactions -> [TransactionRecord] in
                transactions.compactMap {
                    self?.transactionRecord(fromTransaction: $0)
                }
            }
            .eraseToAnyPublisher()
    }

}

public extension SpvBaseAdapter {

    var lastBlockObservable: AnyPublisher<Void, Never> {
        lastBlockSignal
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.global(qos: .userInitiated), latest: true)
            .eraseToAnyPublisher()
    }

    var syncStateObservable: AnyPublisher<Void, Never> {
        syncStateSignal
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.global(qos: .userInitiated), latest: true)
            .eraseToAnyPublisher()
    }

    var balanceObservable: AnyPublisher<Void, Never> {
        balanceSignal.eraseToAnyPublisher()
    }

    var transactionsObservable: AnyPublisher<Void, Never> {
        transactionsSignal.eraseToAnyPublisher()
    }

    func start() {
        self.abstractKit.start()
    }
    
    func stop() {
        self.abstractKit.stop()
    }

    func refresh() {
        self.abstractKit.start()
    }

    var spendableBalance: Decimal {
        Decimal(abstractKit.balance.spendable) / coinRate
    }

    var unspendableBalance: Decimal {
        Decimal(abstractKit.balance.unspendable) / coinRate
    }

    var lastBlockInfo: BlockInfo? {
        abstractKit.lastBlockInfo
    }

    var syncState: BitcoinCore.KitState {
        abstractKit.syncState
    }

    func receiveAddress() -> String {
        abstractKit.receiveAddress()
    }

    func validate(amount: Decimal, address: String?) throws {
        guard amount <= availableBalance(for: address) else {
            throw SendError.insufficientAmount
        }
    }

//    func sendSingle(to address: String, amount: Decimal, sortType: TransactionDataSortType) -> AnyPublisher<Void, Error> {
//        let satoshiAmount = convertToSatoshi(value: amount)
//
//
//        return Single.create { [unowned self] observer in
//            do {
//                _ = try self.abstractKit.send(to: address, value: satoshiAmount, feeRate: self.feeRate, sortType: sortType)
//                observer(.success(()))
//            } catch {
//                observer(.error(error))
//            }
//
//            return Disposables.create()
//        }
//    }

    func buildForSign(target: String, amount: Decimal, feeRate: Int, changeScript: Data?, isReplacedByFee: Bool) throws -> [Data] {
        let amount = convertToSatoshi(value: amount)
        return try abstractKit.createRawHashesToSign(to: target, value: amount, feeRate: feeRate, sortType: .none, changeScript: changeScript, isReplacedByFee: isReplacedByFee)
    }
    
    func buildForSend(target: String, amount: Decimal, feeRate: Int, derSignatures: [Data], changeScript: Data?, isReplacedByFee: Bool) throws -> Data {
        let amount = convertToSatoshi(value: amount)
        return try abstractKit.createRawTransaction(to: target, value: amount, feeRate: feeRate, sortType: .none, signatures: derSignatures, changeScript: changeScript, isReplacedByFee: isReplacedByFee)
    }
    
    func fee(for value: Decimal, address: String?, feeRate: Int, senderPay: Bool, changeScript: Data?, isReplacedByFee: Bool) -> Decimal {
        let amount = convertToSatoshi(value: value)
        var fee: Int = 0
        do {
            fee = try abstractKit.fee(for: amount, toAddress: address, feeRate: feeRate, senderPay: senderPay, changeScript: changeScript, isReplacedByFee: isReplacedByFee)
        } catch {
//            fee = (try? kit.fee(for: amount, toAddress: address, feeRate: feeRate, senderPay: false, changeScript: changeScript, isReplacedByFee: isReplacedByFee)) ?? 0
            print(error)
        }
        
        return Decimal(fee) / coinRate
    }
    
    func availableBalance(for address: String?) -> Decimal {
        let amount = (try? abstractKit.maxSpendableValue(toAddress: address, feeRate: feeRate, changeScript: nil, isReplacedByFee: false)) ?? 0
        return Decimal(amount) / coinRate
    }

    func maxSpendLimit() -> Int? {
        do {
            return try abstractKit.maxSpendLimit()
        } catch {
            return 0
        }
    }

    func minSpendableAmount(for address: String?) -> Decimal {
        Decimal(abstractKit.minSpendableValue(toAddress: address)) / coinRate
    }

    func fee(for value: Decimal, address: String?, senderPay: Bool, changeScript: Data?) -> Decimal {
        do {
            let amount = convertToSatoshi(value: value)
            let fee = try abstractKit.fee(for: amount, toAddress: address, feeRate: feeRate, senderPay: senderPay, changeScript: changeScript, isReplacedByFee: false)
            return Decimal(fee) / coinRate
        } catch {
            return 0
        }
    }

    func printDebugs() {
        print(abstractKit.debugInfo)
        print()
        print(abstractKit.statusInfo)
    }

    func rawTransaction(transactionHash: String) -> String? {
        abstractKit.rawTransaction(transactionHash: transactionHash)
    }

}

enum SendError: Error {
    case insufficientAmount
}
