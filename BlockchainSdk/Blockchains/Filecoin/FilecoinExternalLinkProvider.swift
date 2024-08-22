//
//  FilecoinExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 22.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct FilecoinExternalLinkProvider: ExternalLinkProvider {
    private let baseExplorerUrl = "https://filfox.info"
    
    var testnetFaucetURL: URL? {
        URL(string: "https://faucet.calibnet.chainsafe-fil.io")
    }
    
    func url(transaction hash: String) -> URL? {
        // TODO: [FILECOIN] Unsupported ?
        nil
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }
}
