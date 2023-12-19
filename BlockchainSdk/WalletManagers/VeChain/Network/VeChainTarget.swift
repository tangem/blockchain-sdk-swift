//
//  VeChainTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct VeChainTarget {
    let baseURL: URL
    let target: Target
}

// MARK: - Auxiliary types

extension VeChainTarget {
    enum Target {
        case viewAccount(address: String)
        case sendTransaction(rawTransaction: String)
        case transactionStatus(transactionHash: String, includePending: Bool, rawOutput: Bool)
    }
}

// MARK: - TargetType protocol conformance

extension VeChainTarget: TargetType {
    var path: String {
        switch target {
        case .viewAccount(let address):
            return "/accounts/\(address)"
        case .sendTransaction:
            return "/transactions"
        case .transactionStatus(let transactionHash, _, _):
            return "/transactions/\(transactionHash)"
        }
    }
    
    var method: Moya.Method {
        switch target {
        case .viewAccount, .transactionStatus:
            return .get
        case .sendTransaction:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch target {
        case .viewAccount:
            return .requestPlain
        case .transactionStatus(_, let includePending, let rawOutput):
            let parameters = [
                "pending": includePending,
                "raw": rawOutput,
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case .sendTransaction(let rawTransaction):
            return .requestJSONEncodable(VeChainNetworkParams.Transaction(raw: rawTransaction))
        }
    }
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]
    }
}
