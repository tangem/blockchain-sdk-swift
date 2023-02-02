//
//  TONNetwork.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TONNodeName: Int, CaseIterable {
    case toncenter
    case getblock
    case nownodes
    
    var hasTestnent: Bool {
        switch self {
        case .toncenter:
            return true
        case .getblock, .nownodes:
            return false
        }
    }
    
    func isAvailable(with config: BlockchainSdkConfig) -> Bool {
        switch self {
        case .toncenter:
            return true
        case .getblock:
            return !config.getBlockApiKey.isEmpty
        case .nownodes:
            return !config.nowNodesApiKey.isEmpty
        }
    }
    
}

extension TONNodeName: Comparable {
    static func <(lhs: TONNodeName, rhs: TONNodeName) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct TONNetworkNode {
    
    var config: BlockchainSdkConfig
    var nodeName: TONNodeName
    var isTestnet: Bool
    
    var endpoint: RPCEndpoint {
        switch nodeName {
        case .toncenter:
            let url = isTestnet ? URL(string: "https://testnet.toncenter.com/api/v2/")! : URL(string: "https://toncenter.com/api/v2/")!
            
            return RPCEndpoint(
                url: url,
                apiKeyHeaderName: Constants.toncenterApiKeyHeaderName,
                apiKeyHeaderValue: isTestnet ? "53b83aa857cacc8d29ec0df8cfb000fd814b972fa89f1b15ba0220af11b51a33" :  "21e8fb0fa0b6a4dcb14524489fd22c8b8904209fa9df19b227d7b8b30ca22de9"
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
        guard nodeName.isAvailable(with: config) else {
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
