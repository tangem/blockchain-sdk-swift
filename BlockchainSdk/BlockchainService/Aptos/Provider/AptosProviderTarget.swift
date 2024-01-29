//
//  AptosProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

/*
 https://aptos.dev/nodes/aptos-api-spec
 */

struct AptosProviderTarget: TargetType {
    // MARK: - Properties
    
    private let node: AptosProviderNode
    private let targetType: TargetType
    
    // MARK: - Init
    
    init(node: AptosProviderNode, targetType: TargetType) {
        self.node = node
        self.targetType = targetType
    }
    
    var baseURL: URL {
        return node.url
    }

    var path: String {
        switch targetType {
        case .accounts(let address):
            return "v1/accounts/\(address)"
        case .accountsResources(let address):
            return "v1/accounts/\(address)/resources"
        case .estimateGasPrice:
            return "v1/estimate_gas_price"
        case .submitTransaction:
            return "v1/transactions"
        }
    }
    
    var method: Moya.Method {
        switch targetType {
        case .accounts, .accountsResources, .estimateGasPrice:
            return .get
        case .submitTransaction:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch targetType {
        case .accounts, .accountsResources, .estimateGasPrice:
            return .requestPlain
        case .submitTransaction:
            return .requestParameters(parameters: [:], encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        let headers: [String : String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        return headers
    }
}

extension AptosProviderTarget {
    enum TargetType {
        /*
         Return the authentication key and the sequence number for an account address. Optionally, a ledger version can be specified. If the ledger version is not specified in the request, the latest ledger version is used.
         */
        case accounts(address: String)
        
        /*
         Retrieves all account resources for a given account and a specific ledger version. If the ledger version is not specified in the request, the latest ledger version is used.

         The Aptos nodes prune account state history, via a configurable time window. If the requested ledger version has been pruned, the server responds with a 410.
         */
        case accountsResources(address: String)
        
        /*
         Retrieve on-chain committed transactions. The page size and start ledger version can be provided to get a specific sequence of transactions.
         */
        case estimateGasPrice
        
        /*
         This endpoint accepts transaction submissions in two formats.

         To submit a transaction as JSON, you must submit a SubmitTransactionRequest. To build this request, do the following:

         Encode the transaction as BCS. If you are using a language that has
         native BCS support, make sure of that library. If not, you may take advantage of /transactions/encode_submission. When using this endpoint, make sure you trust the node you're talking to, as it is possible they could manipulate your request. 2. Sign the encoded transaction and use it to create a TransactionSignature. 3. Submit the request. Make sure to use the "application/json" Content-Type.

         To submit a transaction as BCS, you must submit a SignedTransaction encoded as BCS. See SignedTransaction in types/src/transaction/mod.rs. Make sure to use the application/x.aptos.signed_transaction+bcs Content-Type.
         */
        case submitTransaction
    }
}
