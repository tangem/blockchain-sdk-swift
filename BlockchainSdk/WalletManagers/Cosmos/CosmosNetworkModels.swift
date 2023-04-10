//
//  CosmosNetworkModels.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Account

struct CosmosAccountResponse: Decodable {
    let account: Account
}

extension CosmosAccountResponse {
    struct Account: Decodable {
        let accountNumber: String
        let sequence: String
    }
}

// MARK: - Balance

struct CosmosBalanceResponse: Decodable {
    let balances: [Balance]
}

extension CosmosBalanceResponse {
    struct Balance: Decodable {
        let denom: String
        let amount: String
    }
}

// MARK: - Simulate

struct CosmosSimulateResponse: Decodable {
    let gasInfo: GasInfo
}

extension CosmosSimulateResponse {
    struct GasInfo: Decodable {
      let gasUsed: String
    }
}

// MARK: - TX

struct CosmosTxResponse: Decodable {
    let txResponse: TxResponse
}

extension CosmosTxResponse {
    struct TxResponse: Decodable {
        let txhash: String
    }
}
