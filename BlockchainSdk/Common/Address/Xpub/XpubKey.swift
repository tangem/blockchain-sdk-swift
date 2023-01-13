//
//  XpubKey.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct XpubKey: Equatable {
    public let depth: Int
    public let parentFingerprint: Data
    public let childNumber: UInt32
    public let chainCode: Data
    public let publicKey: Data

    /// Master key
    public init(chainCode: Data, publicKey: Data) throws {
        try self.init(depth: 0, parentFingerprint: Data(hexString: "0x00000000"), childNumber: 0, chainCode: chainCode, publicKey: publicKey)
    }

    public init(depth: Int, parentFingerprint: Data, childNumber: UInt32, chainCode: Data, publicKey: Data) throws {
        self.depth = depth
        self.parentFingerprint = parentFingerprint
        self.childNumber = childNumber
        self.chainCode = chainCode
        self.publicKey = publicKey

        _ = try Secp256k1Key(with: publicKey)
    }

    public init(depth: Int, parentKey: Data, childNumber: UInt32, chainCode: Data, publicKey: Data) throws {
        let key = try Secp256k1Key(with: parentKey).compress()
        let fingerprint = key.sha256Ripemd160.prefix(4)
        try self.init(depth: depth, parentFingerprint: fingerprint, childNumber: childNumber, chainCode: chainCode, publicKey: publicKey)
    }

    public init(from xpubString: String, version: XpubVersion) throws {
        let serializer = XpubSerializer(version: version)
        self = try serializer.deserialize(from: xpubString)
    }

    public func serialize(for version: XpubVersion) throws -> String {
        let serializer = XpubSerializer(version: version)
        return try serializer.serialize(self)
    }
}
