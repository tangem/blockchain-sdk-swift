//
//  BitcoinAddress.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 26/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import HDWalletKit

public struct BitcoinScriptAddress: Address {
	public let script: HDWalletScript
	public let value: String
    public let localizedName: String
	public let type: AddressType
    
    internal init(script: HDWalletScript, value: String, type: AddressType) {
        self.script = script
        self.value = value
        self.localizedName = type.defaultLocalizedName
        self.type = type
    }
}

