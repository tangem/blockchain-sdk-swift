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
        case getExchangeRate
    }
}

// MARK: - TargetType protocol conformance

extension HederaTarget: TargetType {
    var baseURL: URL {
        switch target {
        case .getAccounts, .getExchangeRate:
            return configuration.url
        }
    }

    var path: String {
        switch target {
        case .getAccounts:
            return "accounts"
        case .getExchangeRate:
            return "network/exchangerate"
        }
    }

    var method: Moya.Method {
        switch target {
        case .getAccounts, .getExchangeRate:
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
            let encoding = URLEncoding(
                destination: URLEncoding.queryString.destination,
                arrayEncoding: URLEncoding.queryString.arrayEncoding,
                boolEncoding: .literal
            )
            return .requestParameters(parameters: parameters, encoding: encoding)
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
        case .getAccounts, .getExchangeRate:
            if let headersKeyInfo = configuration.headers {
                headers[headersKeyInfo.headerName] = headersKeyInfo.headerValue
            }
        }

        return headers
    }
}
