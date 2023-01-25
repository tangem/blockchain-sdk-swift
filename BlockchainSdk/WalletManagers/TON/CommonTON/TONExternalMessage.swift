//
//  TONExternalMessage.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct TONExternalMessage {
    
    /// Wallet address model
    public let address: TONAddress
    
    /// Result external message
    /// Old wallet_send_generate_external_message
    public let message: TONCell
    
    /// Body of data external message
    public let body: TONCell
    
    /// Signature of signing transaction
    public let signature: Array<UInt8>
    
    /// StateInit cell of wallet
    public let stateInit: TONCell?
    
    /// Code cell of wallet
    public let code: TONCell?
    
    /// Data cell of wallet
    public let data: TONCell?
    
}
