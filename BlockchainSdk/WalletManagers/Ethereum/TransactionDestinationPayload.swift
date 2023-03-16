//
//  TransactionDestinationPayload.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum TransactionDestinationPayload {
    /// Will be amount encoded for send. ONLY for coins
    /// Hex string with value like
    case coin(receiverAddress: String, value: String)
    
    /// ONLY for tokens
    case token(contractAddress: String, data: Data)
    
    public var destination: String {
        switch self {
        case .coin(let address, _):
            return address
        case .token(let contractAddress, _):
            return contractAddress
        }
    }
    
    public var value: String? {
        switch self {
        case .coin(_, let value):
            return value
        case .token:
            return nil
        }
    }
    
    public var data: Data? {
        switch self {
        case .coin:
            return nil
        case .token(_, let data):
            return data
        }
    }
}
