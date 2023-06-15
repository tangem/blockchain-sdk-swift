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

public typealias ExceptionHandlerBuilder = (ExceptionHandlerBuilderInput) -> ExceptionHandlerOutput

public protocol ExceptionHandlerOutput {
    func handleAPISwitch(currentHost: String, nextHost: String?, statusCode: Int, message: String)
}

public final class ExceptionHandlerr {
    
    // MARK: - Static
    
    static let shared: ExceptionHandlerr = .init()
    
    // MARK: - Properties
    
    private var outputs: [ExceptionHandlerOutput] = []
    
    // MARK: - Configuration
    
    func append(output: ExceptionHandlerOutput?) {
        guard let output = output else { return }
        self.outputs.append(output)
    }

    // MARK: - Handle
    
    func handleAPISwitch(currentHost: String, nextHost: String?, statusCode: Int, message: String) {
        self.outputs.forEach { output in
            output.handleAPISwitch(currentHost: currentHost, nextHost: nextHost, statusCode: statusCode, message: message)
        }
    }
    
}
