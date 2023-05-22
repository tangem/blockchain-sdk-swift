//
//  WalletCoreAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import WalletCore

public class WalletCoreAddressService: AddressService {
    
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
        let convertedPublicKey = WalletCorePublicKeyConverterUtil.convert(publicKey: walletPublicKey, publicKeyType: publicKeyType)
        guard let publicKey = PublicKey(data: convertedPublicKey, type: publicKeyType) else {
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

extension WalletCoreAddressService {
    
    static func validate(_ address: String, for blockchain: Blockchain) -> Bool {
        if let coin = CoinType(blockchain) {
            return (try? AnyAddress(string: address, coin: coin)) != nil
        } else {
            return false
        }
    }
    
}

extension WalletCoreAddressService {
    
    enum TWError: Error {
        case makeAddressFailed
    }
    
}
