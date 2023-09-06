//
//  AvalancheExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct AvalancheExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension AvalancheExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.avax-test.network/")
    }
    
    func url(transaction hash: String) -> URL {
        if isTestnet {
            return URL(string: "https://testnet.snowtrace.io/tx/\(hash)")!
        }

        return URL(string: "https://snowtrace.io/tx/\(hash)")!
    }
    
    func url(address: String, contractAddress: String?) -> URL {
        let baseUrl = isTestnet ? "https://testnet.snowtrace.io/" : "https://snowtrace.io/"
        if let contractAddress {
            let url = baseUrl + "token/\(contractAddress)?a=\(address)"
            return URL(string: url)!
        }
        
        let url = baseUrl + "address/\(address)"
        return URL(string: url)!
    }
}
