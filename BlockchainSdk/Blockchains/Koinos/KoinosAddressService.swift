//
//  KoinosAddressService.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

struct KoinosAddressService {
    private let bitcoinLegacyAddressService: BitcoinLegacyAddressService
    
    init(networkParams: INetwork) {
        bitcoinLegacyAddressService = BitcoinLegacyAddressService(networkParams: networkParams)
    }
}

// MARK: - AddressProvider

extension KoinosAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        try bitcoinLegacyAddressService.makeAddress(for: publicKey, with: addressType)
    }
}

// MARK: - AddressValidator

extension KoinosAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        bitcoinLegacyAddressService.validate(address)
    }
}
