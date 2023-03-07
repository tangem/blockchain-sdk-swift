//
//  KaspaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 07.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class KaspaAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        return ""
    }
    
    public func validate(_ address: String) -> Bool {
        return true
    }
}
