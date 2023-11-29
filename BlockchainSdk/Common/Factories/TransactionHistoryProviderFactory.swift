//
//  TransactionHistoryProviderFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionHistoryProviderFactory {
    private let config: BlockchainSdkConfig
    
    // MARK: - Init
    
    public init(config: BlockchainSdkConfig) {
        self.config = config
    }
    
    public func makeProvider(for blockchain: Blockchain) -> TransactionHistoryProvider? {
        // Transaction history is only supported on the mainnet
        guard !blockchain.isTestnet else {
            return nil
        }

        let networkAssembly = NetworkProviderAssembly()
        let input = NetworkProviderAssembly.Input(blockchainSdkConfig: config, blockchain: blockchain)
        
        switch blockchain {
        case .bitcoin,
                .litecoin,
                .dogecoin,
                .dash:
            return UTXOTransactionHistoryProvider(
                blockBookProviders: [
                    networkAssembly.makeBlockBookUtxoProvider(with: input, for: .getBlock),
                    networkAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes)
                ],
                mapper: UTXOTransactionHistoryMapper(blockchain: blockchain)
            )
        case .ethereum,
                .ethereumPoW,
                .ethereumClassic,
                .bsc,
                .avalanche,
                .arbitrum:
            return EthereumTransactionHistoryProvider(
                blockBookProvider: networkAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes),
                mapper: EthereumTransactionHistoryMapper(blockchain: blockchain)
            )
        default:
            return nil
        }
    }
}
