//
//  AddressPublicKeyPair.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct AddressPublicKeyPair: Address {
    public let value: String
    public let publicKey: Wallet.PublicKey
    public let type: AddressType
    
    public var localizedName: String { type.defaultLocalizedName }
}
