//
//  SolanaWalletAssembly.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 08.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Solana_Swift

struct SolanaWalletAssembly: WalletManagerAssembly {
    
    func make(with input: WalletManagerAssemblyInput) throws -> WalletManager {
        return SolanaWalletManager(wallet: input.wallet).then {
            // Need to decide how to store or send websocket link or to parse and add wss prefix
            let endpoints: [RPCEndpoint]
            if input.blockchain.isTestnet {
                endpoints = [
                    .devnetSolana,
                    .devnetGenesysGo,
                ]
            } else {
                let nodeInfoResolver = APINodeInfoResolver(blockchain: input.blockchain, config: input.blockchainSdkConfig)
                endpoints = input.apiInfo.compactMap {
                    guard let api = $0.api else {
                        return nil
                    }

                    if api == .solana {
                        return RPCEndpoint.mainnetBetaSolana
                    }

                    guard
                        let nodeInfo = nodeInfoResolver.resolve(for: $0),
                        var components = URLComponents(url: nodeInfo.url, resolvingAgainstBaseURL: false)
                    else {
                        return nil
                    }

                    components.scheme = SolanaConstants.webSocketScheme
                    guard let urlWebSocket = components.url else {
                        return nil
                    }

                    switch api {
                    case .nownodes, .quicknode:
                        return RPCEndpoint(
                            url: nodeInfo.url,
                            urlWebSocket: urlWebSocket,
                            network: .mainnetBeta
                        )
                    default:
                        return nil
                    }
                }
            }
            
            let networkRouter = NetworkingRouter(endpoints: endpoints)
            let accountStorage = SolanaDummyAccountStorage()
            
            $0.solanaSdk = Solana(router: networkRouter, accountStorage: accountStorage)
            $0.networkService = SolanaNetworkService(solanaSdk: $0.solanaSdk, blockchain: input.blockchain, hostProvider: networkRouter)
        }
    }
}

extension SolanaWalletAssembly {
    enum SolanaConstants {
        static let webSocketScheme = "wss"
    }
}
