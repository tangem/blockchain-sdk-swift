//
//  AddressServiceManagerUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk
import WalletCore

@testable import BlockchainSdk

final class AddressServiceManagerUtility {
    
    func validate(address: String, publicKey: Data, for blockchain: BlockchainSdk.Blockchain) {
        do {
            let addressFromPublicKey = try makeLocalWalletAddressService(publicKey: publicKey, for: blockchain)
            let addressFromTrustWallet = try makeTrustWalletAddressService(publicKey: publicKey, for: blockchain)
            
            validateTRUE(address: addressFromPublicKey, for: blockchain)
            
            XCTAssertEqual(addressFromPublicKey, addressFromTrustWallet)
            XCTAssertEqual(address, addressFromPublicKey)
        } catch {
            XCTFail("__INVALID_ADDRESS__ BLOCKCHAIN FROM PUBLIC KEY!")
        }
        
    }
    
    func validateTRUE(address: String, for blockchain: BlockchainSdk.Blockchain) {
        XCTAssertTrue(TrustWalletAddressService.validate(address, for: blockchain), "__INVALID_ADDRESS__ FROM TW ADDRESS SERVICE")
        XCTAssertTrue(validate(address, for: blockchain), "__INVALID_ADDRESS__ FROM OWN ADDRESS SERVICE")
    }
    
    func validateFALSE(address: String, for blockchain: BlockchainSdk.Blockchain) {
        XCTAssertFalse(TrustWalletAddressService.validate(address, for: blockchain))
        XCTAssertFalse(validate(address, for: blockchain))
    }
    
    func makeTrustWalletAddressService(
        publicKey: Data,
        for blockchain: BlockchainSdk.Blockchain
    ) throws -> String {
        if let coin = CoinType(blockchain) {
            return try TrustWalletAddressService(coin: coin, publicKeyType: .init(blockchain)).makeAddress(from: publicKey)
        } else {
            throw NSError()
        }
    }
    
    func makeLocalWalletAddressService(
        publicKey: Data,
        for blockchain: BlockchainSdk.Blockchain
    ) throws -> String {
        try blockchain.getAddressService().makeAddress(from: publicKey)
    }
    
    // MARK: - Private Implementation
    
    private func validate(_ address: String, for blockchain: BlockchainSdk.Blockchain) -> Bool {
        blockchain.getAddressService().validate(address)
    }
    
}
