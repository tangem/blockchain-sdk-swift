//
//  SuiAddress.swift
//  BlockchainSdk
//
//  Created by Sergei Iakovlev on 27.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SuiAddress {
    public let formattedString: String
    public let curveID: Sui.EllipticCurveID
    
    public init(pubKey data: Data, curveID: Sui.EllipticCurveID = .ed25519) throws {
        let payload = curveID.uint8.data + data
        
        guard let hashed = payload.hashBlake2b(outputLength: 32) else {
            throw WalletCoreAddressService.TWError.makeAddressFailed
        }
        
        let string = hashed.hexString.addHexPrefix()
        
        self.formattedString = string
        self.curveID = curveID
    }
    
    public init(hex string: String, curveID: Sui.EllipticCurveID) throws {
        self.formattedString = string.hasHexPrefix() ? string : string.addHexPrefix()
        self.curveID = curveID
    }
}

