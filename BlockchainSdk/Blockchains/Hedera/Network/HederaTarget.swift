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
    let configuration: NodeInfo
    let target: Target
}

// MARK: - Auxiliary types

extension HederaTarget {
    enum Target {
        case getAccounts(publicKey: String)
        case getAccountBalance(accountId: String)
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
             .getExchangeRate,
             .getAccountBalance:
            return configuration.url
        }
    }

    var path: String {
        switch target {
        case .getAccounts:
            return "accounts"
        case .getAccountBalance:
            return "balances"
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
             .getExchangeRate,
             .getAccountBalance:
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
        case .getAccountBalance(let accountId):
            let parameters: [String: Any] = [
                "account.id": accountId,
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
             .getAccountBalance,
             .getTokens,
             .getExchangeRate:
            if let headersKeyInfo = configuration.headers {
                headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
            }
        }

        return headers
    }
}
