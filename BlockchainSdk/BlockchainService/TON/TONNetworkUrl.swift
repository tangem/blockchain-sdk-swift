//
//  TONNetwork.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum TONNodeName: Int, CaseIterable {
    
    /// Toncenter API JRPC
    /// Fast and reliable HTTP API for The Open Network
    case toncenter
    
    /// Getblock.io
    /// Superior Node Infrastructure for Building dApps
    case getblock
    
    /// NowNodes.io
    /// Full Nodes and Block Explorers
    case nownodes
    
    /// Check verify
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
            return config.toncenterApiKey.isEmpty
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
                apiKeyHeaderValue: config.toncenterApiKey
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
