//
//  APINodeInfoResolver.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct APINodeInfoResolver {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func resolve(for apiInfo: APIInfo) -> NodeInfo? {
        switch apiInfo.type {
        case .public:
            guard
                let link = apiInfo.url,
                let url = URL(string: link)
            else {
                return nil
            }

            return .init(url: url)
        case .private:
            guard let api = apiInfo.api else {
                return nil
            }

            return PrivateAPINodeInfoResolvers(blockchain: blockchain, config: config)
                .resolve(for: api)
        }
    }
}

struct APIKeysInfoProvider {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func apiKeys(for api: PrivateAPI?) -> APIKeyInfo? {
        guard let api else { return nil }

        switch api {
        case .nownodes:
            return NownodesAPIKeysInfoProvider(apiKey: config.nowNodesApiKey)
                .apiKeys(for: blockchain)
        case .arkhiaHedera:
            return .init(
                headerName: Constants.xApiKeyHeaderName,
                headerValue: config.hederaArkhiaApiKey
            )
        case .ton:
            return .init(
                headerName: Constants.xApiKeyHeaderName,
                headerValue: config.tonCenterApiKeys.getApiKey(for: blockchain.isTestnet)
            )
        case .tron:
            return .init(
                headerName: "TRON-PRO-API-KEY",
                headerValue: config.tronGridApiKey
            )
        case .fireAcademy:
            return .init(
                headerName: "X-API-Key",
                headerValue: config.fireAcademyApiKeys.getApiKey(for: blockchain.isTestnet)
            )
        default:
            return nil
        }
    }
}
