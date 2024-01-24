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
        URL(string: "https://dispenser.testnet.aws.algodev.network")
    }

    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.algoexplorer.io/address/\(address)")
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
