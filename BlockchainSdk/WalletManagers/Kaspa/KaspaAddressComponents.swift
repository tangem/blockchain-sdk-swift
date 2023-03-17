//
//  KaspaAddress.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 17.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

enum KaspaAddressType: UInt8 {
        case P2PK_Schnorr
        case P2PK_ECDSA
        case P2SH = 8
   
}

struct KaspaAddressComponents {
    
    let prefix: String
    let type: KaspaAddressType
    let hash: Data
}

extension KaspaAddressComponents {
    init?(_ address: String) {
        guard
            let (prefix, data) = CashAddrBech32.decode(address),
            !data.isEmpty,
            let firstByte = data.first,
            let type = KaspaAddressType(rawValue: firstByte)
        else {
            return nil
        }

        self.prefix = prefix
        self.type = type
        self.hash = data.dropFirst()
    }
}
