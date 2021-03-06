//
//  CardanoAddress.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 31/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct CardanoAddress: Address {
    public var value: String
    public var type: AddressType
    
    public var localizedName: String { type.localizedName }
    
    public init(type: CardanoAddressType, value: String) {
        self.value = value
        self.type = .cardano(type: type)
    }
}
