//
//  StellarWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk

struct StellarWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return StellarWalletManager(wallet: input.wallet).then {
            let urls: [String]
            if !input.blockchain.isTestnet {
                urls = [
                    "https://xlm.nownodes.io/\(input.blockchainSdkConfig.nowNodesApiKey)",
                    "https://xlm.getblock.io/mainnet/\(input.blockchainSdkConfig.getBlockApiKey)",
                    "https://horizon.stellar.org",
                ]
            } else {
                urls = [
                    "https://horizon-testnet.stellar.org",
                ]
            }
            
            let providers = urls.map {
                StellarNetworkProvider(isTestnet: input.blockchain.isTestnet, stellarSdk: StellarSDK(withHorizonUrl: $0))
            }
            
            $0.txBuilder = StellarTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, isTestnet: input.blockchain.isTestnet)
            $0.networkService = StellarNetworkService(providers: providers)
        }
    }
    
}
