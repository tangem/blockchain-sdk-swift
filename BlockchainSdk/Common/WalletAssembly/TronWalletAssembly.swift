//
//  TronWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TronWalletAssembly: WalletAssemblyProtocol {
    
    static func make(with input: BlockchainAssemblyInput) throws -> WalletAssembly {
        return TronWalletManager(wallet: input.wallet).then {
            let network: TronNetwork = input.blockchain.isTestnet ? .nile : .mainnet
            let providers = [
                TronJsonRpcProvider(
                    network: network,
                    tronGridApiKey: nil,
                    configuration: input.networkConfig
                ),
                TronJsonRpcProvider(
                    network: network,
                    tronGridApiKey: input.blockchainConfig.tronGridApiKey,
                    configuration: input.networkConfig
                ),
            ]
            $0.networkService = TronNetworkService(isTestnet: input.blockchain.isTestnet, providers: providers)
            $0.txBuilder = TronTransactionBuilder(blockchain: input.blockchain)
        }
    }
    
}
