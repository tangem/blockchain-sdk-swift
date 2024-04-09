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

    func resolve(for api: NetworkProviderType) -> NodeInfo? {
        let link: String
        switch api {
        case .public(let link):
            guard let url = URL(string: link) else {
                return nil
            }

            return .init(url: url)
        case .nownodes:
            return NownodesAPIResolver(apiKey: config.nowNodesApiKey)
                .resolve(for: blockchain)
        case .quicknode:
            return QuickNodeAPIResolver(config: config)
                .resolve(for: blockchain)
        case .getblock:
            return GetblockAPIResolver(credentials: config.getBlockCredentials)
                .resolve(for: blockchain)
        case .infura:
            return InfuraAPIResolver(config: config)
                .resolve(for: blockchain)
        case .ton:
            guard case .ton = blockchain else {
                return nil
            }

            link = blockchain.isTestnet ?
            "https://testnet.toncenter.com/api/v2" :
            "https://toncenter.com/api/v2"
        case .tron:
            guard case .tron = blockchain else {
                return nil
            }

            link = "https://api.trongrid.io"
        case .adalite:
            guard case .cardano = blockchain else {
                return nil
            }

            link = "https://explorer2.adalite.io"
        case .tangemRosetta:
            guard case .cardano = blockchain else {
                return nil
            }

            link = "https://ada.tangem.com"
        case .tangemChia:
            guard case .chia = blockchain else {
                return nil
            }

            link = "https://chia.tangem.com"
        case .fireAcademy:
            guard case .chia = blockchain else {
                return nil
            }

            link = "https://kraken.fireacademy.io/leaflet"
        case .arkhiaHedera:
            guard case .hedera = blockchain else {
                return nil
            }

            link = "https://pool.arkhia.io/hedera/mainnet/api/v1"
        case .kaspa:
            guard
                case .kaspa = blockchain,
                let url = config.kaspaSecondaryApiUrl
            else {
                return nil
            }

            link = url
        case .blockchair, .blockcypher, .solana:
            return nil
        }

        guard let url = URL(string: link) else {
            return nil
        }

        let keyInfoProvider = APIKeysInfoProvider(blockchain: blockchain, config: config)
        return .init(
            url: url,
            keyInfo: keyInfoProvider.apiKeys(for: api)
        )
    }
}

struct APIKeysInfoProvider {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func apiKeys(for api: NetworkProviderType?) -> APIKeyInfo? {
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
