//
//  SmartContractProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 29.05.2023.
//

import Foundation

public struct SmartContractProvider: SmartContractProviderType {
    public let url: URL
    public var host: String { url.hostOrUnknown }
    
    public init(url: URL) {
        self.url = url
    }
}
