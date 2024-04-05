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

    func url(address: String, contractAddress: String?) -> URL? {
        let convertedAddress = (try? DecimalBlockchainAddressConverter().convertDecimalBlockchainAddressToDscAddress(addressHex: address)) ?? address
        return URL(string: "\(baseExplorerUrl)/address/\(convertedAddress)")
    }

    /*
     example: https://explorer.decimalchain.com/transactions/0x6b76b5b9bad031a90fbd904d9e2fdc746e167fd01b15556d61d6c3aac02b7c49
     */
    func url(transaction hash: String) -> URL? {
        return URL(string: "\(baseExplorerUrl)/transactions/\(hash)")
    }
}
