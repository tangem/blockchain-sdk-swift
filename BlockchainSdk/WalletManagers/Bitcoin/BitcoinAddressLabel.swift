//
//  BitcoinAddressLabel.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 13.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum BitcoinAddressLabel: String, AddressLabel {
    case legacy
    case bech32
    case p2sh
    
    public var label: String { self.rawValue }
}
