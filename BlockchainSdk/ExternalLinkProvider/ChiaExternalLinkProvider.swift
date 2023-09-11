//
//  ChiaExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct ChiaExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension ChiaExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://xchdev.com/#!faucet.md")
    }
    
    func url(transaction hash: String) -> URL {
        if isTestnet {
            return URL(string: "https://testnet10.spacescan.io/txns/\(hash)")!
        }
        
        return URL(string: "https://xchscan.com/txns/\(hash)")!
    }
    
    func url(address: String, contractAddress: String?) -> URL {
        if isTestnet {
            return URL(string: "https://testnet10.spacescan.io/address/\(address)")!
        }
        
        return URL(string: "https://xchscan.com/address/\(address)")!
    }
}
