//
//  NexaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 19.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct NexaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }
    
    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://explorer.nexa.org/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        return URL(string: "https://explorer.nexa.org/tx/\(hash)")
    }
}
