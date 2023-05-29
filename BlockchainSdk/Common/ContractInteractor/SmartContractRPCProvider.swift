//
//  SmartContractRPCProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.05.2023.
//

import Foundation

public struct SmartContractRPCProvider: HostProvider {
    let url: URL
    var host: String { url.hostOrUnknown }
}
