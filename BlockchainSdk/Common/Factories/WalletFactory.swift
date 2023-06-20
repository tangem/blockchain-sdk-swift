//
//  WalletFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletFactory {
    private let blockchain: Blockchain
    private var addressProvider: AddressProvider {
        AddressServiceFactory(blockchain: blockchain).makeAddressService()
    }

    public init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    /// With one public key
    func makeWallet(publicKey: Wallet.PublicKey) throws -> Wallet {
        // Temporary for get count on addresses
        let addressTypes: [AddressType] = Array(blockchain.derivationPaths(for: .v2).keys)

        let addresses: [AddressType: PlainAddress] = try addressTypes.reduce(into: [:]) { result, addressType in
            result[addressType] = try addressProvider.makeAddress(for: publicKey, with: addressType)
        }

        return Wallet(blockchain: blockchain, addresses: addresses)
    }

    /// With multisig script public key
    func makeWallet(publicKey: Wallet.PublicKey, pairPublicKey: Data) throws -> Wallet {
        guard let addressProvider = addressProvider as? BitcoinScriptAddressesProvider else {
            throw WalletError.empty
        }

        let addresses = try addressProvider.makeAddresses(publicKey: publicKey, pairPublicKey: pairPublicKey)

        return Wallet(
            blockchain: blockchain,
            addresses: addresses.reduce(into: [:]) { $0[$1.type] = $1 }
        )
    }

    /// With different public keys
    func makeWallet(publicKeys: [AddressType: Wallet.PublicKey]) throws -> Wallet {
        assert(publicKeys[.default] != nil, "PublicKeys have to contains default publicKey")

        let addressProvider = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        let addresses: [AddressType: PlainAddress] = try publicKeys.reduce(into: [:]) { result, args in
            let (addressType, publicKey) = args

            result[addressType] = try addressProvider.makeAddress(for: publicKey, with: addressType)
        }

        return Wallet(blockchain: blockchain, addresses: addresses)
    }
}
