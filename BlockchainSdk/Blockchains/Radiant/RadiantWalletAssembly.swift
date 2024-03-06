//
//  RadiantWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        var providers = [AnyBitcoinNetworkProvider]()

        if let bitcoinCashAddressService = AddressServiceFactory(
            blockchain: input.blockchain
        ).makeAddressService() as? BitcoinCashAddressService {
            providers.append(
                networkProviderAssembly.makeBitcoinCashNowNodesNetworkProvider(
                    input: input,
                    bitcoinCashAddressService: bitcoinCashAddressService
                )
            )
        }

        let transactionBuilder = RadiantTransactionBuilder(
            coinType: .bitcoinCash,
            publicKey: input.wallet.publicKey.blockchainKey,
            decimalValue: Decimal(input.wallet.blockchain.decimalCount),
            walletAddress: input.wallet.address
        )
        
        return try RadiantWalletManager(
            wallet: input.wallet,
            transactionBuilder: transactionBuilder,
            networkService: RadiantNetworkService(providers: providers)
        )
    }
}
