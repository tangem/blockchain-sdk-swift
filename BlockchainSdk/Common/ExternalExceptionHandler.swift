//
//  Analytics.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExternalExceptionInput {
    public let blockchain: Blockchain
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

public typealias ExternalExceptionHandlerBuilder = (ExternalExceptionInput) -> ExternalExceptionHandler

public protocol ExternalExceptionHandler {
    
    func errorSwitchApi(exceptionHost: String, selectedHost: String?, code: Int, message: String)
    
}
