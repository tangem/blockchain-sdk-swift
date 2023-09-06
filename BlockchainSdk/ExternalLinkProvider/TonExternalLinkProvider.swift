//
//  TonExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TonExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension TonExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }
    
    func url(transaction hash: String) -> URL {
        fatalError()
    }
    
    func url(address: String, contractAddress: String?) -> URL {
        let subdomain = isTestnet ? "testnet." : ""
        return URL(string: "https://\(subdomain)tonscan.org/address/\(address)")!
    }
}
