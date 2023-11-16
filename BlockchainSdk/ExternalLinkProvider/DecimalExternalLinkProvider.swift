//
//  DecimalExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct DecimalExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    private let isTestnet: Bool
    
    private var baseExplorerUrl: String {
        if isTestnet {
            return "https://testnet.explorer.decimalchain.com"
        } else {
            return "https://explorer.decimalchain.com"
        }
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
    }

    func url(address: String, contractAddress: String?) -> URL {
        let copyAddress = (try? DecimalUtils().convertErcAddressToDscAddress(addressHex: address)) ?? address
        return URL(string: "\(baseExplorerUrl)/address/\(copyAddress)")!
    }

    func url(transaction hash: String) -> URL {
        URL(string: "\(baseExplorerUrl)/transactions/\(hash)")!
    }
}
