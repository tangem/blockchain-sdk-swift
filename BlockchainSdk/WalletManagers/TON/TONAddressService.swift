//
//  TONAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

public class TONAddressService: AddressService {
    
    /// Generate user-friendly address of wallet by public key
    /// - Parameter walletPublicKey: Data public key wallet
    /// - Returns: User-friendly address
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        guard let publicKey = PublicKey(data: walletPublicKey, type: .ed25519) else {
            throw TONError.exception("Not created public key")
        }
        
        return AnyAddress(publicKey: publicKey, coin: .ton).description
    }
    
    /// Validate address TON wallet with any form
    /// - Parameter address: Any form address wallet
    /// - Returns: Result of validate
    public func validate(_ address: String) -> Bool {
        return AnyAddress(string: address, coin: .ton) != nil
    }
    
}
