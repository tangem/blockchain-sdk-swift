//
//  TrustWalletAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

public class TrustWalletAddressService: AddressService {
    
    private let coin: CoinType
    private let publicKeyType: PublicKeyType
    
    // MARK: - Init
    
    public init(coin: CoinType, publicKeyType: PublicKeyType) {
        self.coin = coin
        self.publicKeyType = publicKeyType
    }
    
    /// Generate address of wallet by public key
    /// - Parameter walletPublicKey: Data public key wallet
    /// - Returns: User-friendly address
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        guard let publicKey = PublicKey(data: walletPublicKey, type: publicKeyType) else {
            throw TWError.makeAddressFailed
        }
        
        return AnyAddress(publicKey: publicKey, coin: coin).description
    }
    
    /// Validate address wallet with any form
    /// - Parameter address: Any form address wallet
    /// - Returns: Result of validate
    public func validate(_ address: String) -> Bool {
        return AnyAddress(string: address, coin: coin) != nil
    }
    
}

extension TrustWalletAddressService {
    
    public enum TWError: Error {
        case makeAddressFailed
    }
    
}
