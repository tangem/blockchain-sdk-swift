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

    private let ethereumAddressService = EthereumAddressService()
    private let converter = DecimalBlockchainAddressConverter()
}

// MARK: - AddressProvider protocol conformance

extension DecimalAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        var address = try ethereumAddressService.makeAddress(for: publicKey, with: addressType)
        
        // If need to convert address to decimal native type
        if case .default = addressType {
            address = try DecimalPlainAddress(
                value: converter.convertDscAddressToDecimalBlockchainAddress(addressHex: address.value),
                publicKey: publicKey,
                type: addressType
            )
        }
        
        return DecimalPlainAddress(value: address.value, publicKey: publicKey, type: addressType)
    }
}

// MARK: - AddressValidator protocol conformance

extension DecimalAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        guard let dscAddress = try? converter.convertDecimalBlockchainAddressToDscAddress(addressHex: address) else {
            return false
        }
        
        return ethereumAddressService.validate(dscAddress)
    }
}
