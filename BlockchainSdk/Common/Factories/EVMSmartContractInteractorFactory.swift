//
//  EVMSmartContractInteractorFactory.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 17/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct EVMSmartContractInteractorFactory {
    private let config: BlockchainSdkConfig

    public init(config: BlockchainSdkConfig) {
        self.config = config
    }

    public func makeInteractor(for blockchain: Blockchain, apiInfo: [APIInfo]) throws -> EVMSmartContractInteractor {
        guard blockchain.isEvm else {
            throw FactoryError.invalidBlockchain
        }

        let networkAssembly = NetworkProviderAssembly()
        let networkService = EthereumNetworkService(
            decimals: blockchain.decimalCount,
            providers: networkAssembly.makeEthereumJsonRpcProviders(with: EVMNetworkProviderAssemblyInput(
                blockchain: blockchain,
                blockchainSdkConfig: config,
                networkConfig: config.networkProviderConfiguration(for: blockchain), 
                apiOrder: [blockchain.codingKey: apiInfo]
            )),
            blockcypherProvider: nil,
            abiEncoder: WalletCoreABIEncoder()
        )

        return networkService
    }
}

public extension EVMSmartContractInteractorFactory {
    enum FactoryError: String, LocalizedError {
        case invalidBlockchain

        public var errorDescription: String? {
            rawValue
        }
    }
}

private extension EVMSmartContractInteractorFactory {
    struct EVMNetworkProviderAssemblyInput: NetworkProviderAssemblyInput {
        var blockchain: Blockchain
        var blockchainSdkConfig: BlockchainSdkConfig
        var networkConfig: NetworkProviderConfiguration
        var apiOrder: APIOrder
    }
}
