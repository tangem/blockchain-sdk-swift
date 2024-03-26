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

extension MoyaProvider {
    // TODO: Andrey Fedorov - Temporary solution, add support for retries and cancellation
    func asyncRequest(for target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }

            request(target) { result in
                switch result {
                case .success(let responseValue):
                    continuation.resume(returning: responseValue)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
