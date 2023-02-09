//
//  EthereumChildWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import stellarsdk
import BitcoinCore

struct EthereumWalletAssembly: WalletAssemblyProtocol {
    
    static func make(with input: BlockchainAssemblyInput) throws -> AssemblyWallet {
        let manager: EthereumWalletManager
        let endpoints = input.blockchain.getJsonRpcEndpoints(
            keys: EthereumApiKeys(
                infuraProjectId: input.blockchainConfig.infuraProjectId,
                nowNodesApiKey: input.blockchainConfig.nowNodesApiKey,
                getBlockApiKey: input.blockchainConfig.getBlockApiKey,
                quickNodeBscCredentials: input.blockchainConfig.quickNodeBscCredentials
            )
        )!
        
        if case .optimism = input.blockchain {
            manager = OptimismWalletManager(wallet: input.wallet, rpcURL: endpoints[0].url)
        } else {
            manager = EthereumWalletManager(wallet: input.wallet)
        }
        
        let blockcypherProvider: BlockcypherNetworkProvider?
        
        if case .ethereum = input.blockchain {
            blockcypherProvider = providerAssembly.makeBlockcypherNetworkProvider(endpoint: .ethereum, with: input)
        } else {
            blockcypherProvider = nil
        }
        
        return try manager.then {
            let chainId = input.blockchain.chainId!
            
            let jsonRpcProviders = endpoints.map {
                var additionalHeaders: [String: String] = [:]
                if let apiKeyHeaderName = $0.apiKeyHeaderName, let apiKeyHeaderValue = $0.apiKeyHeaderValue {
                    additionalHeaders[apiKeyHeaderName] = apiKeyHeaderValue
                }
                
                return EthereumJsonRpcProvider(
                    url: $0.url,
                    additionalHeaders: additionalHeaders,
                    configuration: input.networkConfig
                )
            }
            
            $0.txBuilder = try EthereumTransactionBuilder(walletPublicKey: input.wallet.publicKey.blockchainKey, chainId: chainId)
            $0.networkService = EthereumNetworkService(decimals: input.blockchain.decimalCount,
                                                       providers: jsonRpcProviders,
                                                       blockcypherProvider: blockcypherProvider,
                                                       blockchairProvider: nil) //TODO: TBD Do we need the TokenFinder feature?
        }
    }
    
}
