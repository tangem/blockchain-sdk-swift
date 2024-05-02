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

public struct SendTxError: LocalizedError {
    public let error: Error
    public let tx: String?
    public let lastRetryHost: String?
    
    public var errorDescription: String? {
        """
            description: \(error.localizedDescription)
            tx: \(tx ?? "undefined")
            lastRetryHost: \(lastRetryHost ?? "undefined")
        """
    }
    
    // MARK: - Init
    
    init(error: Error, tx: String? = nil) {
        // Need be use ....
        if let sendError = error as? Self {
            self = sendError
        } else if let providerError = error as? MultiNetworkProviderError {
            self.error = providerError.networkError
            self.tx = tx
            self.lastRetryHost = providerError.lastRetryHost
        } else {
            self.error = error
            self.tx = tx
            self.lastRetryHost = nil
        }
    }
}
