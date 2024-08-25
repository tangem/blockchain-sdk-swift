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
        /// This method returns `nil` because Filecoin does not use transaction hashes as message identifiers.
        /// In other blockchains, a transaction hash can be directly used to generate a URL to explore the transaction details.
        /// However, in Filecoin, message IDs (which are used to identify transactions) are not derived from transaction hashes.
        /// Therefore, constructing a URL in the format `"\(baseExplorerUrl)/message/\(hash)"` is not applicable.
        nil
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(baseExplorerUrl)/address/\(address)")
    }
}
