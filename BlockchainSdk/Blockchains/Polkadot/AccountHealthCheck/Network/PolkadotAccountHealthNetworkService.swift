//
//  PolkadotAccountHealthNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PolkadotAccountHealthNetworkService {
    func getAccountHealthInfo(account: String) async throws -> PolkadotAccountHealthInfo
    func getTransactionsList(account: String, afterId: Int) async throws -> [PolkadotTransaction]
    func getTransactionDetails(hash: String) async throws -> PolkadotTransactionDetails
}
