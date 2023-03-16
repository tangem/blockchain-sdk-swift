//
//  EthereumDestinationPayload.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct EthereumDestinationPayload {
    public let targetAddress: String
    public let value: String?
    public let data: Data?
    
    /// - Parameters:
    ///   - targetAddress: Destination address. For token it'll be a contract address. For coin it'll be a receiver(user) address
    ///   - value: In hex encoded amount to send
    ///   - data: Data to be send as `txData`. Required when `targetAddress` is a smart contract address.
    public init(targetAddress: String, value: String? = nil, data: Data? = nil) {
        self.targetAddress = targetAddress
        self.value = value
        self.data = data
    }
}
