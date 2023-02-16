//
//  TransactionHistoryLoader.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 14/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

@available(iOS 13.0, *)
public protocol TransactionHistoryLoader {
    func loadTransactionHistory() -> AnyPublisher<[Transaction], Error>
}

protocol TransactionHistoryProvider {
    func loadTransactionHistory(address: String) -> AnyPublisher<[TransactionHistoryRecordConvertible], Error>
}

protocol TransactionHistoryRecordConvertible {
    var sourceAddress: String { get }
    var destinationAddress: String { get }
    var status: TransactionStatus { get }
    var hash: String { get }
    
    var date: Date? { get }
    var tokenContractAddress: String? { get }
    
    func amount(decimalCount: Int) -> Decimal?
    func fee(decimalCount: Int) -> Decimal?
}
