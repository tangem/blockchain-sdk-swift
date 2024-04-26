//
//  PolkadotAddress.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

struct PolkadotAddress {
    let string: String

    init?(string: String, network: PolkadotNetwork) {
        guard Self.isValid(string, in: network) else {
            return nil
        }
        self.string = string
    }

    init(publicKey: Data, network: PolkadotNetwork) {
        let accountData = SS58.accountData(from: publicKey)
        self.string = SS58.address(from: accountData, type: network.addressPrefix)
    }

    // Raw representation (without the prefix) was used in the older protocol versions
    func bytes(raw: Bool) -> Data? {
        SS58.bytes(string: string, raw: raw)
    }

    static private func isValid(_ address: String, in network: PolkadotNetwork) -> Bool {
        SS58.isValidAddress(address, type: network.addressPrefix)
    }
}
