//
//  Moya+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 13.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import AnyCodable

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
