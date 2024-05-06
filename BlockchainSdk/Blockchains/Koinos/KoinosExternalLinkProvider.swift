//
//  KoinosExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: [KOINOS] Implement KoinosExternalLinkProvider
struct KoinosExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension KoinosExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        nil
    }
    
    func url(transaction hash: String) -> URL? {
        nil
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        nil
    }
}
