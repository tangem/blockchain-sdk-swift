//
//  XpubSerializer.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import web3swift

/// https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#serialization-format
struct XpubSerializer {
    private let version: XpubVersion

    init(version: XpubVersion) {
        self.version = version
    }

    func serialize(_ key: XpubKey) throws -> String {
        let compressedKey = try Secp256k1Key(with: key.publicKey).compress()

        var data = Data(capacity: Constants.dataLength)

        data += version.rawValue.bytes4
        data += key.depth.byte
        data += key.parentFingerprint
        data += key.childNumber.bytes4
        data += key.chainCode
        data += compressedKey
        
        guard data.count == Constants.dataLength else {
            throw XpubError.wrongLength
        }

        let resultString = Array(data).base58CheckEncodedString
        return resultString
    }

    func deserialize(from xpubString: String) throws -> XpubKey {
        guard let data = xpubString.base58CheckDecodedData else {
            throw XpubError.decodingFailed
        }

        guard data.count == Constants.dataLength else {
            throw XpubError.wrongLength
        }

        let decodedVersion = UInt32(data.prefix(4).toInt())

        guard decodedVersion == version.rawValue else {
            throw XpubError.wrongVersion
        }

        let depth = data.dropFirst(4).prefix(1).toInt()
        let parentFingerprint = data.dropFirst(5).prefix(4)
        let childNumber = UInt32(data.dropFirst(9).prefix(4).toInt())
        let chainCode = data.dropFirst(13).prefix(32)
        let compressedKey = data.suffix(33)

        let xpub = try XpubKey(depth: depth,
                               parentFingerprint: parentFingerprint,
                               childNumber: childNumber,
                               chainCode: chainCode,
                               publicKey: compressedKey)

        return xpub
    }
}

extension XpubSerializer {
    enum Constants {
        static let dataLength: Int = 78
    }
}
