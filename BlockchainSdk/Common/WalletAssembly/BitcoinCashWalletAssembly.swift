//
//  BitcoinCashWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct BitcoinCashWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try BitcoinCashWalletManager(wallet: input.wallet).then {
            let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()
            let bitcoinManager = BitcoinManager(networkParams: input.blockchain.isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams(),
                                                walletPublicKey: compressed,
                                                compressedWalletPublicKey: compressed,
                                                bip: .bip44)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager, addresses: input.wallet.addresses)
            
            //TODO: Add testnet support. Maybe https://developers.cryptoapis.io/technical-documentation/general-information/what-we-support
            var providers = [AnyBitcoinNetworkProvider]()

            providers.append(
                networkProviderAssembly.makeBitcoinCashNowNodesNetworkProvider(
                    input: input,
                    addressService: AddressServiceFactory(blockchain: .bitcoinCash).makeAddressService()
                )
            )
            
            providers.append(
                contentsOf: networkProviderAssembly.makeBlockchairNetworkProviders(endpoint: .bitcoinCash, with: input)
            )
            
            $0.networkService = BitcoinCashNetworkService(providers: providers)
        }
    }
    
}
