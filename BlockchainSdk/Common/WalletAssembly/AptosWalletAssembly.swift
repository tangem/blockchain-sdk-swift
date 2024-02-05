//
//  AptosWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosWalletAssembly: WalletManagerAssembly {
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        
        var providers: [AptosNetworkProvider] = []
        
        providers.append(
            contentsOf: [
                makeNetworkMainnetProvider(
                    for: .nownodes,
                    with: input.blockchainSdkConfig.nowNodesApiKey,
                    networkConfig: input.networkConfig
                ),
                makeNetworkMainnetProvider(
                    for: .getblock,
                    with: input.blockchainSdkConfig.getBlockCredentials.credential(for: input.blockchain, type: .rest),
                    networkConfig: input.networkConfig
                ),
                makeNetworkMainnetProvider(
                    for: .aptoslabs,
                    networkConfig: input.networkConfig
                ),
            ]
        )
        
        let txBuilder = AptosTransactionBuilder(
            publicKey: input.wallet.publicKey.blockchainKey,
            walletAddress: input.wallet.address,
            isTestnet: input.blockchain.isTestnet,
            decimalValue: input.blockchain.decimalValue
        )
        
        let networkService = AptosNetworkService(
            blockchain: input.blockchain,
            providers: providers
        )
        
        return AptosWalletManager(wallet: input.wallet, transactionBuilder: txBuilder, networkService: networkService)
    }
    
    // MARK: - Private Implementation
    
    private func makeNetworkMainnetProvider(
        for node: AptosProviderType,
        with apiKeyValue: String? = nil,
        networkConfig: NetworkProviderConfiguration
    ) -> AptosNetworkProvider {
        AptosNetworkProvider(
            node: .init(
                type: .nownodes,
                apiKeyValue: apiKeyValue
            ),
            networkConfig: networkConfig
        )
    }
}
