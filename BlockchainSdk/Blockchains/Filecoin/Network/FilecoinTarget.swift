//
//  FilecoinTarget.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct FilecoinTarget: TargetType {
    enum FilecoinTargetType {
        case getActorInfo(address: String)
        case getGasUnitPrice(transactionInfo: FilecoinTxInfo)
        case getGasLimit(transactionInfo: FilecoinTxInfo)
        case submitTransaction(signedTransactionBody: FilecoinSignedTransactionBody)
        
        var method: String {
            switch self {
            case .getActorInfo:
                "Filecoin.StateGetActor"
            case .getGasUnitPrice:
                "Filecoin.GasEstimateFeeCap"
            case .getGasLimit:
                "Filecoin.GasEstimateGasLimit"
            case .submitTransaction:
                "Filecoin.MpoolPush"
            }
        }
    }
    
    let node: NodeInfo
    let type: FilecoinTargetType
    
    init(node: NodeInfo, _ type: FilecoinTargetType) {
        self.node = node
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
        case .getActorInfo(let address):
                .requestJSONRPC(
                    id: Constants.jsonRPCMethodId,
                    method: type.method,
                    params: [
                        address,
                        nil
                    ]
                )
            
        case .getGasUnitPrice(let transactionInfo):
                .requestJSONRPC(
                    id: Constants.jsonRPCMethodId,
                    method: type.method,
                    params: [
                        FilecoinDTOMapper.convertTransactionBody(from: transactionInfo),
                        nil,
                        nil
                    ]
                )
            
        case .getGasLimit(let transactionInfo):
                .requestJSONRPC(
                    id: Constants.jsonRPCMethodId,
                    method: type.method,
                    params: [
                        FilecoinDTOMapper.convertTransactionBody(from: transactionInfo),
                        nil
                    ]
                )
            
        case .submitTransaction(let signedTransactionBody):
                .requestJSONRPC(
                    id: Constants.jsonRPCMethodId,
                    method: type.method,
                    params: [
                        signedTransactionBody
                    ]
                )
        }
    }
    
    var headers: [String : String]?
}

private extension FilecoinTarget {
    enum Constants {
        static let jsonRPCMethodId: Int = 1
    }
}
