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
        case .bitcoinCash:
            return UTXOTransactionHistoryProvider(
                blockBookProviders: [
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
        case .tron:
            return TronTransactionHistoryProvider(
                blockBookProvider: networkAssembly.makeBlockBookUtxoProvider(with: input, for: .nowNodes),
                mapper: TronTransactionHistoryMapper(blockchain: blockchain)
            )
        case .polygon:
            return PolygonTransactionHistoryProvider(
                mapper: PolygonTransactionHistoryMapper(blockchain: blockchain),
                networkConfiguration: input.networkConfig,
                targetConfiguration: .polygonScan(isTestnet: blockchain.isTestnet, apiKey: config.polygonScanApiKey)
            )
        case .algorand(_, let isTestnet):
            let node: AlgorandProviderNode
            if isTestnet {
                node = .init(type: .idxFullNode(isTestnet: isTestnet))
            } else {
                node = .init(type: .idxNownodes, apiKeyValue: config.nowNodesApiKey)
            }

            return AlgorandTransactionHistoryProvider(
                node: node,
                networkConfig: input.networkConfig,
                mapper: AlgorandTransactionHistoryMapper(blockchain: input.blockchain)
            )
        default:
            return nil
        }
    }
}
