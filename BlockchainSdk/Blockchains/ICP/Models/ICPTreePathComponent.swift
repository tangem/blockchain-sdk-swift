//
//  ICPTreePathComponent.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ICPStateTreePath: Hashable {
    public let components: [ICPStateTreePathComponent]
    
    public init(_ path: String) {
        let splitComponents = path.split(separator: "/").map(String.init)
        self.components = splitComponents.map { .string($0) }
    }
    
    public init(_ components: any Sequence<ICPStateTreePathComponent>) {
        self.components = Array(components)
    }
    
    public var firstComponent: ICPStateTreePathComponent? { components.first }
    public var removingFirstComponent: ICPStateTreePath { .init(components.suffix(from: 1)) }
    public var isEmpty: Bool { components.isEmpty }
    
    static func readStateRequestPaths(requestID: Data) -> [ICPStateTreePath] {
        [
            ["time"],
            ["request_status", .data(requestID), "status"],
            ["request_status", .data(requestID), "reply"],
            ["request_status", .data(requestID), "reject_code"],
            ["request_status", .data(requestID), "reject_message"]
        ].map { ICPStateTreePath($0) }
    }
}

public enum ICPStateTreePathComponent: Hashable {
    case data(Data)
    case string(String)
    
    public var stringValue: String? {
        guard case .string(let string) = self else { return nil }
        return string
    }
    
    public var dataValue: Data? {
        guard case .data(let data) = self else { return nil }
        return data
    }
}

// MARK: Encoding
public extension ICPStateTreePath {
    func encodedComponents() -> [Data] { components.map { $0.encoded() } }
}

public extension ICPStateTreePathComponent {
    func encoded() -> Data {
        switch self {
        case .data(let data): return data
        case .string(let string): return Data(string.utf8)
        }
    }
}

// MARK: convenience initialisers
extension ICPStateTreePath: ExpressibleByStringLiteral {
    public init(stringLiteral path: String) {
        self.init(path)
    }
}

extension ICPStateTreePath: ExpressibleByArrayLiteral {
    public init(arrayLiteral components: ICPStateTreePathComponent...) {
        self.init(components)
    }
}

extension ICPStateTreePathComponent: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}
