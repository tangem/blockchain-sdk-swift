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
    let address: TONAddress
    
    /// Result external message
    /// Old wallet_send_generate_external_message
    let message: TONCell
    
    /// Body of data external message
    let body: TONCell
    
    /// Signature of signing transaction
    let signature: Array<UInt8>
    
    /// StateInit cell of wallet
    let stateInit: TONCell?
    
    /// Code cell of wallet
    let code: TONCell?
    
    /// Data cell of wallet
    let data: TONCell?
    
}
