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
    
    func validate(privateKey: PrivateKey, for blockchain: BlockchainSdk.Blockchain) {
        do {
            let publicKey = try privateKey.getPublicKey(coinType: .init(blockchain)).data
            let twAddress = try makeTrustWalletAddressService(publicKey: publicKey, for: blockchain)
            let localAddress = try makeLocalWalletAddressService(publicKey: publicKey, for: blockchain)
            
            XCTAssertEqual(twAddress, localAddress)
            
            validate(address: twAddress, publicKey: publicKey, for: blockchain)
        } catch {
            XCTFail("__INVALID_ADDRESS__ TW ADDRESS DID NOT CREATED!")
        }
    }
    
    func validate(address: String, publicKey: Data, for blockchain: BlockchainSdk.Blockchain) {
        do {
            let addressFromPublicKey = try blockchain.getAddressService().makeAddress(from: publicKey)
            validateTRUE(address: addressFromPublicKey, for: blockchain)
            
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
    
    // MARK: - Private Implementation
    
    private func validate(_ address: String, for blockchain: BlockchainSdk.Blockchain) -> Bool {
        blockchain.getAddressService().validate(address)
    }
    
    private func makeTrustWalletAddressService(
        publicKey: Data,
        for blockchain: BlockchainSdk.Blockchain
    ) throws -> String {
        try TrustWalletAddressService(coin: .init(blockchain), publicKeyType: .init(blockchain)).makeAddress(from: publicKey)
    }
    
    private func makeLocalWalletAddressService(
        publicKey: Data,
        for blockchain: BlockchainSdk.Blockchain
    ) throws -> String {
        try blockchain.getAddressService().makeAddress(from: publicKey)
    }
    
}
