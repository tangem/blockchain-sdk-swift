//
//  StellarAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk

public class StellarAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        try walletPublicKey.validateAsEdKey()
        
        let publicKey = try PublicKey(Array(walletPublicKey))
        let keyPair = KeyPair(publicKey: publicKey)
        return keyPair.accountId
    }
    
    public func validate(_ address: String) -> Bool {
        let keyPair = try? KeyPair(accountId: address)
        return keyPair != nil
    }
}
