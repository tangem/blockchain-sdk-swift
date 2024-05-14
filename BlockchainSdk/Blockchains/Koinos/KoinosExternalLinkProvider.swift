//
//  KoinosExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 06.05.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// TODO: [KOINOS] Implement KoinosExternalLinkProvider
// https://tangem.atlassian.net/browse/IOS-6760
struct KoinosExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension KoinosExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        fatalError("Not implemented")
    }
    
    func url(transaction hash: String) -> URL? {
        fatalError("Not implemented")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        fatalError("Not implemented")
    }
}
