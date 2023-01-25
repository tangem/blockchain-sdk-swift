//
//  TONSigner.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol TONSigner: AnyObject {
    
    /// Run signing message TON transaction
    /// - Parameters:
    ///   - message: Data of message transaction
    ///   - publicKey: Public key wallet
    /// - Returns: Publisher of result sign transaction where Data = result of signing
    func sign(message: Data, publicKey: Data) -> AnyPublisher<Data, Error>
    
}
