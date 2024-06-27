//
//  KoinosTarget.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct KoinosTarget: TargetType {
    enum KoinosTargetType {
        case getKoinBalance(args: String)
        case getRc(address: String)
        case getNonce(address: String)
        case getResourceLimits
        case submitTransaction(transaction: KoinosProtocol.Transaction)
        
        var method: String {
            switch self {
            case .getKoinBalance:
                "chain.read_contract"
            case .getRc:
                "chain.get_account_rc"
            case .getNonce:
                "chain.get_account_nonce"
            case .getResourceLimits:
                "chain.get_resource_limits"
            case .submitTransaction:
                "chain.submit_transaction"
            }
        }
    }
    
    let node: NodeInfo
    let type: KoinosTargetType
    let koinContractAbi: KoinContractAbi
    
    init(node: NodeInfo, koinContractAbi: KoinContractAbi, _ type: KoinosTargetType) {
        self.node = node
        self.koinContractAbi = koinContractAbi
        self.type = type
    }

    var baseURL: URL {
        node.url
    }

    var path: String {
        ""
    }
    
    var method: Moya.Method {
        .post
    }
    
    var task: Task {
        switch type {
        case let .getKoinBalance(args):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.ReadContract.RequestParams(
                    contractId: koinContractAbi.contractID,
                    entryPoint: KoinContractAbi.BalanceOf.entryPoint,
                    args: args
                ),
                encoder: JSONEncoder.withSnakeCaseStrategy
            )
            
        case let .getRc(address):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.GetAccountRC.RequestParams(account: address)
            )
            
        case let .getNonce(address):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.GetAccountNonce.RequestParams(account: address)
            )
            
        case .getResourceLimits:
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: nil
            )
            
        case let .submitTransaction(transaction):
            return .requestJSONRPC(
                id: Constants.jsonRPCMethodId,
                method: type.method,
                params: KoinosMethod.SubmitTransaction.RequestParams(transaction: transaction, broadcast: true)
            )
        }
    }
    
    var headers: [String : String]?
}

private extension KoinosTarget {
    enum Constants {
        static let jsonRPCMethodId: Int = 1
    }
}