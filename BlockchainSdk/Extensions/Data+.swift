//
//  Data+.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import class WalletCore.DataVector

extension Data {
    var bytes: Array<UInt8> {
        return Array(self)
    }
    
    // TODO: Andrey Fedorov - There are several problems with this extension (IOS-4990):
    // - It has basically the same implementation as `leadingZeroPadding(toLength:)` method
    // - It ignores the `length` parameter
    // - The naming is quite ambigious
    @available(*, deprecated, message: "Use 'leadingZeroPadding(toLength:)' instead")
    public func aligned(to length: Int = 32) -> Data {
        let bytesCount = self.count
        
        guard bytesCount < length else {
            return self
        }
        
        let prefix = Data(repeating: 0, count: 32 - bytesCount)
        
        return prefix + self
    }
    
    public func leadingZeroPadding(toLength newLength: Int) -> Data {
        guard count < newLength else { return self }

        let prefix = Data(repeating: UInt8(0), count: newLength - count)
        return prefix + self
    }

    public func trailingZeroPadding(toLength newLength: Int) -> Data {
        guard count < newLength else { return self }

        let suffix = Data(repeating: UInt8(0), count: newLength - count)
        return self + suffix
    }

    func validateAsEdKey() throws {
        _ = try Curve25519.Signing.PublicKey(rawRepresentation: self)
    }

    func validateAsSecp256k1Key() throws {
        _ = try Secp256k1Key(with: self)
    }

    func asDataVector() -> DataVector {
        return DataVector(data: self)
    }
}
