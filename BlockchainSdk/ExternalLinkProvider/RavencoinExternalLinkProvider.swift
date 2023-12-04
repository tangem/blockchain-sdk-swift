//
//  RavencoinExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 06.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinExternalLinkProvider {
    private let isTestnet: Bool
    
    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }
}

extension RavencoinExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        return URL(string: "https://faucet.kava.io")!
    }
    
    func url(transaction hash: String) -> URL? {
        if isTestnet {
            return URL(string: "https://testnet.ravencoin.network/tx/\(hash)")!
        }

        return URL(string: "https://api.ravencoin.org/tx/\(hash)")!
    }
    
    func url(address: String, contractAddress: String?) -> URL {
        if isTestnet {
            return URL(string: "https://testnet.ravencoin.network/address/\(address)")!
        }

        return URL(string: "https://api.ravencoin.org/address/\(address)")!
    }
}
