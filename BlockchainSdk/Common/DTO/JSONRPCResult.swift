//
//  JSONRPCResult.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 23.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct JSONRPCResult<Output, Failure> where Output: Decodable, Failure: Decodable, Failure: Swift.Error {
    let jsonrpc: String
    let id: String
    let result: Result<Output, Failure>
}

// MARK: - Decodable protocol conformance

extension JSONRPCResult: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let result: Result<Output, Failure>

        if let success = try container.decodeIfPresent(Output.self, forKey: .result) {
            result = .success(success)
        } else if let failure = try container.decodeIfPresent(Failure.self, forKey: .error) {
            result = .failure(failure)
        } else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Neither \"result\" nor \"error\" keys present in the JSON payload"
            )
            throw DecodingError.valueNotFound(type(of: result), context)
        }

        self.init(
            jsonrpc: try container.decode(forKey: .jsonrpc),
            id: try container.decode(forKey: .id),
            result: result
        )
    }
}

// MARK: - Auxiliary types

private extension JSONRPCResult {
    enum CodingKeys: CodingKey {
        case jsonrpc
        case id
        case result
        case error
    }
}
