//
//  DucatusWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BitcoinCore

struct DucatusWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return try DucatusWalletManager(wallet: input.wallet).then {
            let bitcoinManager = BitcoinManager(networkParams: DucatusNetworkParams(), walletPublicKey: input.wallet.defaultPublicKey.blockchainKey, compressedWalletPublicKey: try Secp256k1Key(with: input.wallet.defaultPublicKey.blockchainKey).compress(), bip: .bip44)
            
            $0.txBuilder = BitcoinTransactionBuilder(bitcoinManager: bitcoinManager,
                                                     addresses: input.wallet.addresses.all.map { $0.address })
            $0.networkService = DucatusNetworkService(configuration: input.networkConfig)
        }
    }
    
}
