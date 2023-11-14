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
        return URL(string: "https://core.app/tools/testnet-faucet/")
    }
    
    func url(transaction hash: String) -> URL {
        if isTestnet {
            return URL(string: "https://testnet.avascan.info/blockchain/c/tx/\(hash)")!
        }

        return URL(string: "https://subnets.avax.network/c-chain/tx/\(hash)")!
    }

    func url(address: String, contractAddress: String?) -> URL {
        if isTestnet {
            let baseUrlString = "https://testnet.avascan.info/blockchain/c/"

            if let contractAddress = contractAddress {
                let urlString = baseUrlString + "token/\(contractAddress)?a=\(address)"
                return URL(string: urlString)!
            }

            let urlString = baseUrlString + "address/\(address)"

            return URL(string: urlString)!
        }

        return URL(string: "https://subnets.avax.network/c-chain/address/\(address)")!
    }
}
