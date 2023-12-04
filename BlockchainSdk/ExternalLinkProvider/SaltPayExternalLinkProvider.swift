//
//  SaltPayExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct SaltPayExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }
    
    func url(transaction hash: String) -> URL? {
        fatalError("Not implement")
    }
    
    func url(address: String, contractAddress: String?) -> URL {
        fatalError("Not implement")
    }
}
