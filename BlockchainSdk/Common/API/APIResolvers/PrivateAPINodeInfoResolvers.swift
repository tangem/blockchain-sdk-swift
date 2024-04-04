//
//  PrivateAPINodeInfoResolvers.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 04/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PrivateAPINodeInfoResolvers {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func resolve(for api: PrivateAPI) -> NodeInfo? {
        let link: String
        switch api {
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
            link = blockchain.isTestnet ?
            "https://testnet.toncenter.com/api/v2" :
            "https://toncenter.com/api/v2"
        case .tron:
            link = "https://api.trongrid.io"
        case .adalite:
            link =  "https://explorer2.adalite.io"
        case .tangemRosetta:
            link = "https://ada.tangem.com"
        case .tangemChia:
            link = "https://chia.tangem.com"
        case .fireAcademy:
            link = "https://kraken.fireacademy.io/leaflet"
        case .hedera:
            link = "https://pool.arkhia.io/hedera/mainnet/api/v1"
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
