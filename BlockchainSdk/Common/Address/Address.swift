//
//  Address.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct Address {
    public let label: AddressLabel
    public let value: String
    
    public init(value: String, label: AddressLabel = DefaultAddressLabel()) {
        self.value = value
        self.label = label
    }
}

public protocol AddressLabel {
    var label: String { get }
}

public extension AddressLabel {
    var isDefault: Bool { label == DefaultAddressLabel().label }
}

public struct DefaultAddressLabel: AddressLabel {
    public var label: String = ""
    
    public init() {}
}
