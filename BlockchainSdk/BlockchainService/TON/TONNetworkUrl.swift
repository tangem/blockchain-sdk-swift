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
    
    func isAvailable(with apiKey: String?) -> Bool {
        return !(apiKey?.isEmpty ?? true)
    }
    
}

extension TONNodeName: Comparable {
    static func <(lhs: TONNodeName, rhs: TONNodeName) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct TONNetworkNode {
    
    var apiKeyValue: String
    var nodeName: TONNodeName
    var isTestnet: Bool
    
    var endpoint: RPCEndpoint {
        switch nodeName {
        case .toncenter:
            let url = isTestnet ? URL(string: "https://testnet.toncenter.com/api/v2/")! : URL(string: "https://toncenter.com/api/v2/")!
            
            return RPCEndpoint(
                url: url,
                apiKeyHeaderName: Constants.toncenterApiKeyHeaderName,
                apiKeyHeaderValue: apiKeyValue
            )
        case .getblock:
            return RPCEndpoint(
                url: URL(string: "https://ton.getblock.io/\(apiKeyValue)/mainnet")!,
                apiKeyHeaderName: Constants.getBlockApiKeyHeaderName,
                apiKeyHeaderValue: apiKeyValue
            )
        case .nownodes:
            return RPCEndpoint(
                url: URL(string: "https://ton.nownodes.io/\(apiKeyValue)")!
            )
        }
    }
    
    // TODO: - Только ключ
    
    init?(apiKeyValue: String?, nodeName: TONNodeName, isTestnet: Bool) {
        guard nodeName.isAvailable(with: apiKeyValue) else {
            return nil
        }
        
        // Verify available testnet node
        if isTestnet {
            guard nodeName.hasTestnent else {
                return nil
            }
        }
        
        self.apiKeyValue = apiKeyValue ?? ""
        self.nodeName = nodeName
        self.isTestnet = isTestnet
    }
    
}
