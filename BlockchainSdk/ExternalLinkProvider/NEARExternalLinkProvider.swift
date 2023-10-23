//
//  NEARExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 12.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARExternalLinkProvider: ExternalLinkProvider {
    private let isTestnet: Bool

    init(
        isTestnet: Bool
    ) {
        self.isTestnet = isTestnet
    }

    var testnetFaucetURL: URL? {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4070)
        return URL(string: "about:blank")!
    }

    func url(address: String, contractAddress: String?) -> URL {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4070)
        return URL(string: "about:blank")!
    }

    func url(transaction hash: String) -> URL {
        // TODO: Andrey Fedorov - Add actual implementation (IOS-4070)
        return URL(string: "about:blank")!
    }
}
