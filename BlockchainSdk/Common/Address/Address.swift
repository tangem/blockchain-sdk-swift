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
    var type: AddressType { get }
}

public enum AddressType: Equatable {
    case `default`
	case legacy
    
    public var defaultLocalizedName: String {
        switch self {
        case .default:
            return "address_type_default".localized
        case .legacy:
            return "address_type_legacy".localized
        }
    }
}

public struct PlainAddress: Address {
    public let value: String
    public let localizedName: String
    public let type: AddressType
}

extension PlainAddress {
    init(value: String, type: AddressType) {
        self.value = value
        self.type = type
        self.localizedName = type.defaultLocalizedName
    }
}
