//
//  CosmosChain.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

enum CosmosChain {
    case cosmos(testnet: Bool)
    // ancient testnet network, we only use it for unit tests
    case gaia
}

// Keplr is a Cosmos network software wallet
// Keplr registry contains lots of goodies, for example:
// https://github.com/chainapsis/keplr-chain-registry/blob/main/cosmos/cosmoshub.json
extension CosmosChain {
    // https://cosmos.directory/cosmoshub
    func urls(for config: BlockchainSdkConfig) -> [String] {
        switch self {
        case .cosmos(let testnet):
            if testnet {
                return [
                    "https://rest.seed-01.theta-testnet.polypore.xyz",
                ]
            } else {
                return [
                    "https://atom.nownodes.io/\(config.nowNodesApiKey)",
                    "https://atom.getblock.io/\(config.getBlockApiKey)",
                    
                    "https://cosmos-mainnet-rpc.allthatnode.com:1317",
                    
                    // This is a REST proxy combining the servers below (and others)
                    "https://rest.cosmos.directory/cosmoshub",
                    
                    "https://cosmoshub-api.lavenderfive.com",
                    "https://rest-cosmoshub.ecostake.com",
                    "https://lcd.cosmos.dragonstake.io",
                ]
            }
        case .gaia:
            fatalError()
        }
    }
    
    // Either feeCurrencies/coinMinimalDenom from Keplr registry
    // or
    // params/bond_denom field from /cosmos/staking/v1beta1/params request
    var smallestDenomination: String {
        switch self {
        case .cosmos:
            return "uatom"
        case .gaia:
            return "muon"
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .cosmos(let testnet):
            return .cosmos(testnet: testnet)
        case .gaia:
            return .cosmos(testnet: true)
        }
    }
    
    // Either chainId from Keplr registry
    // or
    // node_info/network field from /node_info request
    var chainID: String {
        switch self {
        case .cosmos(let testnet):
            return testnet ? "theta-testnet-001" : "cosmoshub-4"
        case .gaia:
            return "gaia-13003"
        }
    }
    
    // feeCurrencies/gasPriceStep field from Keplr registry
    var gasPrices: [Double] {
        switch self {
        case .cosmos:
            return [
                0.01,
                0.025,
                0.03,
            ]
        case .gaia:
            fatalError()
        }
    }
    
    var coin: CoinType {
        switch self {
        case .cosmos, .gaia:
            return .cosmos
        }
    }
}
