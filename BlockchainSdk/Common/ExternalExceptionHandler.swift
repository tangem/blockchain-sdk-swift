//
//  Analytics.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExternalExceptionHandler {
    
    /// Register BlockchainSdk exception for external service logger
    func log(exception message: String, for host: String)
    
}
