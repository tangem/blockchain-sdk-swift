//
//  PolkadotWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct PolkadotWalletAssembly: BlockchainAssemblyProtocol {
    
    func assembly(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        let network: PolkadotNetwork = input.blockchain.isTestnet ? .westend : .polkadot
        
        return PolkadotWalletManager(network: network, wallet: input.wallet).then {
            let providers = network.urls.map { url in
                PolkadotJsonRpcProvider(url: url, configuration: input.networkConfig)
            }
            $0.networkService = PolkadotNetworkService(providers: providers, network: network)
            $0.txBuilder = PolkadotTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, network: network)
        }
    }
    
}
