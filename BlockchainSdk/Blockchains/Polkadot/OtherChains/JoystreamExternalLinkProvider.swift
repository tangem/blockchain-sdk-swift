//
//  JoystreamExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 17.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct JoystreamExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }
    
    func url(transaction hash: String) -> URL? {
        return URL(string: "https://joystream.subscan.io/extrinsic/\(hash)")
    }
    
    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "https://joystream.subscan.io/account/\(address)")
    }
}
