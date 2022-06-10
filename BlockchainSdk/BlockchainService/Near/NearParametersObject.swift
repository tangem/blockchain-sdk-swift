//
//  NearParametersObject.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 06.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct NearRequestAccessViewBodyObject: Encodable {
    let jsonrpc: String = "2.0"
    let id: String = UUID().uuidString
    let method: String = "query"
    let params: NearAccessViewParameters
    
    struct NearAccessViewParameters: Encodable {
        let requestType: String = NearAPIMethod.viewAccessKey
        let finality = "final"
        let accountId: String
        let publicKey: String
    }
}

struct NearRequestAccessViewListBodyObject: Encodable {
    let jsonrpc: String = "2.0"
    let id: String = UUID().uuidString
    let method: String = "query"
    let params: NearAccessViewParameters
    
    struct NearAccessViewParameters: Encodable {
        let requestType: String = NearAPIMethod.viewAccessKeyList
        let finality = "final"
        let accountId: String
    }
}

struct NearGasPriceBodyObject: Encodable {
    let jsonrpc: String = "2.0"
    let id: String = UUID().uuidString
    let method: String = NearAPIMethod.gasPrice
    /// block_height or "block_hash" or null
    let params: [String]? = nil
}

struct NearAccountInfoBodyObject: Encodable {
    let jsonrpc: String = "2.0"
    let id: String = UUID().uuidString
    let method: String = "query"
    let params: NearAccountParameters
    
    struct NearAccountParameters: Encodable {
        let requestType: String = NearAPIMethod.viewAccount
        let finality = "final"
        let accountId: String
    }
}

struct NearSendTransactionBodyObject: Encodable {
    let jsonrpc: String = "2.0"
    let id: String = UUID().uuidString
    let method: String = NearAPIMethod.sendTransactionAsync
    /// SignedTransaction encoded in base64
    let params: [String]
}

struct NearAccountHistoryBodyObject: Encodable {
    let jsonrpc: String = "2.0"
    let id: String = UUID().uuidString
    let method: String = NearAPIMethod.experimentalChanges
    let params: Params
    
    struct Params: Encodable {
        let changesType: String = "account_changes"
        let accountIds: [String]
        let finality: String = "final"
    }
}

struct NearLastBlockBodyObject: Encodable {
    let jsonrpc: String = "2.0"
    let id: String = UUID().uuidString
    let method: String = NearAPIMethod.lastBlock
    let params: [String: String] = ["finality": "final"]
}
