//
//  HederaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct HederaAddressService: AddressService {
    private let walletCoreAddressService = WalletCoreAddressService(coin: .hedera)

    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        // TODO: Andrey Fedorov - Fetch account ID from a local storage or fetch it asynchronously from the network (IOS-4567)
        return try walletCoreAddressService.makeAddress(for: publicKey, with: addressType)
    }
    
    func validate(_ address: String) -> Bool {
        return walletCoreAddressService.validate(address)
    }
}
