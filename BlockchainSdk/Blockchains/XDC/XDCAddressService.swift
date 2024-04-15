//
//  XDCAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct XDCAddressService {

    // MARK: - Private Properties

    private let ethereumAddressService = WalletCoreAddressService(coin: .ethereum)
    private let converter = XDCAddressConverter()
}

// MARK: - AddressProvider protocol conformance

extension XDCAddressService: AddressProvider {
    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        let ethAddress = try ethereumAddressService.makeAddress(for: publicKey, with: addressType)

        switch addressType {
        case .default:
            return PlainAddress(
                value: converter.convertToXDCAddress(ethAddress.value),
                publicKey: ethAddress.publicKey,
                type: ethAddress.type)
        case .legacy:
            return ethAddress
        }
    }
}

// MARK: - AddressValidator protocol conformance

extension XDCAddressService: AddressValidator {
    func validate(_ address: String) -> Bool {
        return ethereumAddressService.validate(converter.convertToETHAddress(address))
    }
}
