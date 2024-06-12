//
//  CardanoResponseMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 24.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CardanoResponseMapper {
    func mapToCardanoAddressResponse(
        tokens: [Token],
        unspentOutputs: [CardanoUnspentOutput],
        recentTransactionsHashes: [String]
    ) -> CardanoAddressResponse {
        let coinBalance: UInt64 = unspentOutputs.reduce(0) { $0 + $1.amount }

        let tokenBalances: [Token: UInt64] = tokens.reduce(into: [:]) { tokenBalances, token in
            // Collecting of all output balance
            tokenBalances[token, default: 0] += unspentOutputs.reduce(0) { result, output in
                // Sum with each asset in output amount
                result + output.assets.reduce(into: 0) { result, asset in
                    // We can not compare full contractAddress and policyId
                    // Because from API we receive only the policyId e.g. `1d7f33bd23d85e1a25d87d86fac4f199c3197a2f7afeb662a0f34e1e`
                    // But from our API sometimes we receive the contractAddress like `policyId + assetNameHex`
                    // e.g. 1d7f33bd23d85e1a25d87d86fac4f199c3197a2f7afeb662a0f34e1e776f726c646d6f62696c65746f6b656e
                    if token.contractAddress.hasPrefix(asset.policyID) {
                        result += asset.amount
                    }
                }
            }
        }
        
        return CardanoAddressResponse(
            balance: coinBalance,
            tokenBalances: tokenBalances,
            recentTransactionsHashes: recentTransactionsHashes,
            unspentOutputs: unspentOutputs
        )
    }
}
