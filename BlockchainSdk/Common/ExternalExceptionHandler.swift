//
//  Analytics.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExceptionHandlerBuilderInput {
    public let blockchain: Blockchain
    
    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }
}

public typealias ExceptionHandlerBuilder = (ExceptionHandlerBuilderInput) -> ExceptionHandler

public protocol ExceptionHandler {
    func handleAPISwitch(currentHost: String, nextHost: String?, statusCode: Int, message: String)
}
