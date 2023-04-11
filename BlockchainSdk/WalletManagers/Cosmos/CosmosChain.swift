//
//  CosmosChain.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum CosmosChain {
    case cosmos(testnet: Bool)
}

// Keplr is a Cosmos network software wallet
// Keplr registry contains lots of goodies, for example:
// https://github.com/chainapsis/keplr-chain-registry/blob/main/cosmos/cosmoshub.json
extension CosmosChain {
    // Either feeCurrencies/coinMinimalDenom from Keplr registry
    // or
    // params/bond_denom field from /cosmos/staking/v1beta1/params request
    var smallestDenomination: String {
        switch self {
        case .cosmos(let testnet):
            assert(testnet)
            return testnet ? "uatom" : "!!! TODO !!!"
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .cosmos(let testnet):
            return .tron(testnet: testnet) // TODO
        }
    }
    
    // node_info/network field from /node_info request
    var chainID: String {
        switch self {
        case .cosmos(let testnet):
            assert(testnet)
            return testnet ? "theta-testnet-001" : "!!! TODO !!!"
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
}
