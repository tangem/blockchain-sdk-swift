//
//  HederaTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct HederaTarget {
    let configuration: HederaTargetConfiguration
    let target: Target
}

// MARK: - Auxiliary types

extension HederaTarget {
    enum Target {
        case getAccounts(publicKey: String)
        case getTokens(accountId: String)
        case getExchangeRate
    }
}

// MARK: - TargetType protocol conformance

extension HederaTarget: TargetType {
    var baseURL: URL {
        switch target {
        case .getAccounts,
             .getTokens,
             .getExchangeRate:
            return configuration.baseURL
        }
    }

    var path: String {
        switch target {
        case .getAccounts:
            return "accounts"
        case .getTokens(let accountId):
            return "accounts/\(accountId)/tokens"
        case .getExchangeRate:
            return "network/exchangerate"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getAccounts,
             .getTokens,
             .getExchangeRate:
            return .get
        }
    }

    var task: Moya.Task {
        switch target {
        case .getAccounts(let publicKey):
            let parameters: [String: Any] = [
                "balance": false,
                "account.publickey": publicKey,
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.tangem)
        case .getTokens:
            let parameters: [String: Any] = [
                "limit": UInt8.max,     // 255 unique tokens per account should be enough
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.tangem)
        case .getExchangeRate:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var headers = [
            "Content-Type": "application/json",
            "Accept": "application/json",
        ]

        switch target {
        case .getAccounts,
             .getTokens,
             .getExchangeRate:
            if let apiKeyHeaderName = configuration.apiKeyHeaderName {
                headers[apiKeyHeaderName] = configuration.apiKeyHeaderValue
            }
        }

        return headers
    }
}
