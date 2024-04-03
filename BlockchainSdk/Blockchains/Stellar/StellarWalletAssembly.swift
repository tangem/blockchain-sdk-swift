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
            let blockchain = input.blockchain
            let links: [String]
            if blockchain.isTestnet {
                links = TestnetAPIURLProvider(blockchain: blockchain).urls()?.map(\.link) ?? []
            } else {
                let linkResolver = APILinkResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)

                links = input.apiInfo.compactMap(linkResolver.resolve(for:))
            }
            let providers: [StellarNetworkProvider] = links.map {
                StellarNetworkProvider(
                    isTestnet: blockchain.isTestnet,
                    stellarSdk: .init(withHorizonUrl: $0)
                )
            }

            $0.txBuilder = StellarTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, isTestnet: input.blockchain.isTestnet)
            $0.networkService = StellarNetworkService(providers: providers)
        }
    }
    
}
