//
//  EthereumClassicExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumClassicExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension EthereumClassicExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://kottifaucet.me")
    }
    
    func url(transaction hash: String) -> URL {
        if isTestnet {
            return URL(string: "https://blockscout.com/etc/kotti/tx/\(hash)/transactions")!
        }
        
        return URL(string: "https://blockscout.com/etc/mainnet/tx/\(hash)/transactions")!
    }

    func url(address: String, contractAddress: String?) -> URL {
        if isTestnet {
            return URL(string: "https://blockscout.com/etc/kotti/address/\(address)/transactions")!
        }
        
        return URL(string: "https://blockscout.com/etc/mainnet/address/\(address)/transactions")!
    }
}
