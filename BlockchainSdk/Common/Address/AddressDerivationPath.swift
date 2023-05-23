//
//  AddressDerivationPath.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 23.05.2023.
//

import Foundation

import struct TangemSdk.DerivationPath

public struct AddressDerivationPath {
    public let legacy: DerivationPath?
    public let `default`: DerivationPath?
    
    public var asDictionary: [AddressType: DerivationPath?] {
        [.legacy: legacy, .default: `default`]
    }
    
    public var asArray: [DerivationPath?] {
        [legacy, `default`]
    }
    
    public init(legacy: DerivationPath? = nil, `default`: DerivationPath? = nil) {
        self.legacy = legacy
        self.`default` = `default`
    }
}

extension AddressDerivationPath {
    public static let empty = AddressDerivationPath()
}
