//
//  ICPAddressService.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 12.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ICPAddressService: AddressService {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> any Address {
        let principal = try ICPCryptography.selfAuthenticatingPrincipal(uncompressedPublicKey: publicKey.blockchainKey)
    }
    
    func validate(_ address: String) -> Bool {
        fatalError()
    }
}
