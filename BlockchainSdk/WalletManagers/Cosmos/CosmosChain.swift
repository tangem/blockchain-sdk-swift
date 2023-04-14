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
}

// Keplr is a Cosmos network software wallet
// Keplr registry contains lots of goodies, for example:
// https://github.com/chainapsis/keplr-chain-registry/blob/main/cosmos/cosmoshub.json
extension CosmosChain {
    // https://cosmos.directory/cosmoshub
    var urls: [String] {
        switch self {
        case .cosmos(let testnet):
            if testnet {
                return [
                    "https://rest.seed-01.theta-testnet.polypore.xyz",
                ]
            } else {
                return [
                    "https://cosmos-mainnet-rpc.allthatnode.com:1317",
                ]
            }
        }
    }
    
    // Either feeCurrencies/coinMinimalDenom from Keplr registry
    // or
    // params/bond_denom field from /cosmos/staking/v1beta1/params request
    var smallestDenomination: String {
        switch self {
        case .cosmos:
            return "uatom"
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .cosmos(let testnet):
            return .cosmos(testnet: testnet)
        }
    }
    
    // Either chainId from Keplr registry
    // or
    // node_info/network field from /node_info request
    var chainID: String {
        switch self {
        case .cosmos(let testnet):
            return testnet ? "theta-testnet-001" : "cosmoshub-4"
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
        }
    }
    
    var coin: CoinType {
        switch self {
        case .cosmos:
            return .cosmos
        }
    }
}
