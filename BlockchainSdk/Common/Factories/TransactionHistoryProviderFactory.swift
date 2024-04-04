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
    private let apiOrder: APIOrder

    // MARK: - Init
    
    public init(config: BlockchainSdkConfig, apiOrder: APIOrder) {
        self.config = config
        self.apiOrder = apiOrder
    }
    
    public func makeProvider(for blockchain: Blockchain) -> TransactionHistoryProvider? {
        // Transaction history is only supported on the mainnet
        guard !blockchain.isTestnet else {
            return nil
        }

        let networkAssembly = NetworkProviderAssembly()
        let input = NetworkProviderAssembly.Input(
            blockchainSdkConfig: config,
            blockchain: blockchain,
            apiOrder: apiOrder
        )

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
        case .algorand(_, let isTestnet):
            if isTestnet {
                guard let url = TransactionHistoryAPILinkProvider(config: config).link(for: blockchain, api: nil) else {
                    return nil
                }
                return AlgorandTransactionHistoryProvider(
                    blockchain: input.blockchain,
                    node: .init(url: url),
                    networkConfig: input.networkConfig
                )
            } else {
                guard let url = TransactionHistoryAPILinkProvider(config: config).link(for: blockchain, api: .nownodes) else {
                    return nil
                }
                let apiKeyInfo = NownodesAPIKeysInfoProvider(apiKey: config.nowNodesApiKey).apiKeys(for: blockchain)

                return AlgorandTransactionHistoryProvider(
                    blockchain: input.blockchain,
                    node: .init(url: url, keyInfo: apiKeyInfo),
                    networkConfig: input.networkConfig
                )
            }
        default:
            return nil
        }
    }
}
