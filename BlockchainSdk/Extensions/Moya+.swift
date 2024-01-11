//
//  Moya+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import struct AnyCodable.AnyEncodable

extension Moya.Task {
    static func requestJSONRPC(
        id: String,
        method: String,
        params: Encodable,
        encoder: JSONEncoder? = nil
    ) -> Self {
        let jsonRPCParams = JSONRPCParams(
            id: id,
            method: method,
            params: AnyEncodable(params)
        )

        if let encoder = encoder {
            return .requestCustomJSONEncodable(jsonRPCParams, encoder: encoder)
        }

        return .requestJSONEncodable(jsonRPCParams)
    }
}

extension MoyaError {
    var asWalletError: WalletError? {
        switch self {
        case .jsonMapping,
             .objectMapping,
             .imageMapping,
             .stringMapping:
            return WalletError.failedToParseNetworkResponse
        case .statusCode,
             .underlying,
             .encodableMapping,
             .requestMapping,
             .parameterEncoding:
            return nil
        @unknown default:
            assertionFailure("Unknown error kind received: \(self)")
            return nil
        }
    }
}
