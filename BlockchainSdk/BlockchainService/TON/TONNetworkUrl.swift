//
//  TONNetwork.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TONNodeName {
    case toncenter
    case getblock
    case nownodes
    
    var isAvailable: Bool {
        switch self {
        case .toncenter:
            return true
        case .getblock, .nownodes:
            return false
        }
    }
    
    var hasTestnent: Bool {
        switch self {
        case .toncenter:
            return true
        case .getblock, .nownodes:
            return false
        }
    }
}

struct TONNetworkNode {
    
    var config: BlockchainSdkConfig
    var nodeName: TONNodeName
    var isTestnet: Bool
    
    var endpoint: RPCEndpoint {
        switch nodeName {
        case .toncenter:
            return RPCEndpoint(
                url: URL(string: "https://toncenter.com/api/v2/")!,
                apiKeyHeaderName: Constants.toncenterApiKeyHeaderName,
                apiKeyHeaderValue: "21e8fb0fa0b6a4dcb14524489fd22c8b8904209fa9df19b227d7b8b30ca22de9"
            )
        case .getblock:
            return RPCEndpoint(
                url: URL(string: "https://ton.getblock.io/\(config.getBlockApiKey)/mainnet")!,
                apiKeyHeaderName: Constants.getBlockApiKeyHeaderName,
                apiKeyHeaderValue: config.getBlockApiKey
            )
        case .nownodes:
            return RPCEndpoint(
                url: URL(string: "https://ton.nownodes.io/\(config.nowNodesApiKey)")!
            )
        }
    }
    
    init?(config: BlockchainSdkConfig, nodeName: TONNodeName, isTestnet: Bool) {
        guard nodeName.isAvailable else {
            return nil
        }
        
        // Verify available testnet node
        if isTestnet {
            guard nodeName.hasTestnent else {
                return nil
            }
        }
        
        self.config = config
        self.nodeName = nodeName
        self.isTestnet = isTestnet
    }
}
