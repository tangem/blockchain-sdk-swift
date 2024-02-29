//
//  KaspaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct KaspaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.kaspanet.io")
    }
    
    func url(transaction hash: String) -> URL? {
        return URL(string: "https://explorer.kaspa.org/txs/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://explorer.kaspa.org/addresses/\(address)")
    }
}
