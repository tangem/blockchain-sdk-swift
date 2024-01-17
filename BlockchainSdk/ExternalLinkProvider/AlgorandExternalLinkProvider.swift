//
//  AlgorandExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AlgorandExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        // TODO: - Write faucet
        return nil
    }

    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            // TODO: - Insert url explorer link
            return nil
        }

        return URL(string: "https://algoexplorer.io/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        if isTestnet {
            // TODO: - Insert url transaction link
            return nil
        }

        return URL(string: "https://algoexplorer.io/tx/\(hash)")
    }
}
