//
//  RavencoinWalletAssembly.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct RavencoinWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        try RavencoinWalletManager(wallet: input.wallet).then {
            let compressed = try Secp256k1Key(with: input.wallet.publicKey.blockchainKey).compress()

            let bitcoinManager = BitcoinManager(
                networkParams: input.blockchain.isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams(),
                walletPublicKey: input.wallet.publicKey.blockchainKey,
                compressedWalletPublicKey: compressed,
                bip: .bip44
            )

            $0.txBuilder = BitcoinTransactionBuilder(
                bitcoinManager: bitcoinManager,
                addresses: input.wallet.addresses
            )
            
            $0.networkService = BitcoinNetworkService(
                providers: [
                    networkProviderAssembly
                        .makeBlockBookUtxoProvider(with: input, for: .getBlock)
                        .eraseToAnyBitcoinNetworkProvider()
                ]
            )
        }
    }
    
}
