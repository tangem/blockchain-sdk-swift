//
//  BitcoinAddress.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 26/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import HDWalletKit

public struct BitcoinAddress: Address {
	public let type: BitcoinAddressType
	public let value: String
	
	public var localizedName: String { type.localizedName }
	
	public init(type: BitcoinAddressType, value: String) {
		self.type = type
		self.value = value
	}
}

public struct BitcoinScriptAddress: Address {
	public let script: HDWalletScript
	public let value: String
	public let type: BitcoinAddressType
	
	public var localizedName: String { type.localizedName }
	
}
