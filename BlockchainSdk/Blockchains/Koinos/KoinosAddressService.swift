//
//  KoinosAddressService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: [KOINOS] Implement KoinosAddressService
struct KoinosAddressService {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

// MARK: - AddressProvider

extension KoinosAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        throw BlockchainSdkError.notImplemented
    }
}

// MARK: - AddressValidator

extension KoinosAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        false
    }
}
