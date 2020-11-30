//
//  Address.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol Address {
    var value: String { get }
    var localizedName: String { get }
}

public struct PlainAddress: Address {
    public let value: String
    public var localizedName: String { "" }
    
    public init(value: String) {
        self.value = value
    }
}
