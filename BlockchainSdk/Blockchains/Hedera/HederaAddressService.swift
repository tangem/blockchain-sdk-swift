//
//  HederaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Hedera
import TangemSdk

final class HederaAddressService: AddressService {
    private let isTestnet: Bool

    private lazy var client: Client = {
        return isTestnet ? Client.forTestnet() : Client.forMainnet()
    }()

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func makeAddress(for publicKey: Wallet.PublicKey, with addressType: AddressType) throws -> Address {
        Log.warning(
            """
            Address for the Hedera blockchain (Testnet: \(isTestnet)) is requested but can't be provided. \
            Obtain actual address using `Wallet.address`
            """
        )
        return PlainAddress(value: "", publicKey: publicKey, type: addressType)
    }

    func validate(_ address: String) -> Bool {
        do {
            // We consider an address valid only if it has the `<shard>.<realm>.<last>` (Hedera native) form
            // (i.e. both its `evmAddress` and `alias` properties are nil)
            let accountId = try AccountId.fromString(address)
            let hasEVMAddress = accountId.evmAddress?.toBytes().nilIfEmpty != nil
            let hasAlias = accountId.alias?.toBytes().nilIfEmpty != nil

            return !(hasEVMAddress || hasAlias)
        } catch {
            return false
        }
    }
}
