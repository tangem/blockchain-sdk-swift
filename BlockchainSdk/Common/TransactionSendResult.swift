//
//  TransactionSendResult.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TransactionSendResult {
    public let hash: String
    
    public init(hash: String) {
        self.hash = hash
    }
}
