//
//  Wallet+Addresses.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Wallet {
    public struct Addresses {
        public let `default`: WalletAddress
        public let legacy: WalletAddress?
        
        public var all: [WalletAddress] {
            [`default`, legacy].compactMap { $0 }
        }
    }
}
