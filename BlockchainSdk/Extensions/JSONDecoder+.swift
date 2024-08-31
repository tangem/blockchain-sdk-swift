//
//  JSONDecoder+.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 11/01/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static let customISO8601 = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = DateFormatter.iso8601withFractionalSeconds.date(from: string) ?? DateFormatter.iso8601.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}

extension Encodable {
    func asDictionary(encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try encoder.encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        return dictionary as? [String: Any] ?? [:]
    }
}

extension JSONDecoder {
    static var withSnakeCaseStrategy: JSONDecoder {
        let encoder = JSONDecoder()
        encoder.keyDecodingStrategy = .convertFromSnakeCase
        return encoder
    }
}

extension JSONDecoder {
    static var withUpperCamelToLowerCamelCaseStrategy: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .custom { keys in
            let lastKey = keys.last!.stringValue
            let lowerCamelCaseKey = lastKey.prefix(1).lowercased() + lastKey.dropFirst()
            return AnyKey(stringValue: lowerCamelCaseKey)!
        }
        return decoder
    }
}

private struct AnyKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
