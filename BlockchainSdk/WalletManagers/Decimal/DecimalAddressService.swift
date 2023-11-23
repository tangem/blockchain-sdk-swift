//
//  DecimalAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct DecimalAddressService {
    
    // MARK: - Private Properties
    
    private let isTestnet: Bool
    private let ethereumAddressService = EthereumAddressService()
    
    private let bech32 = Bech32(variant: .bech32)
    private let utils = DecimalBlockchainAddressConverter()
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

// MARK: - AddressProvider protocol conformance

extension DecimalAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> PlainAddress {
        var address = try ethereumAddressService.makeAddress(for: publicKey, with: addressType)
        
        // If need to convert address to decimal native type
        if case .default = addressType {
            address = try .init(
                value: utils.convertErcAddressToDscAddress(addressHex: address.value),
                publicKey: publicKey,
                type: addressType
            )
        }
        
        return .init(value: address.value, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator protocol conformance

extension DecimalAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard let ercAddress = utils.convertDscAddressToErcAddress(addressHex: address) else {
            return false
        }
        
        return ethereumAddressService.validate(ercAddress)
    }
}
