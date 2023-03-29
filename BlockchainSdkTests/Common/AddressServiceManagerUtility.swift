//
//  AddressServiceManagerUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest

@testable import BlockchainSdk

final class AddressServiceManagerUtility {
    
    func validate(address: String, publicKey: Data, for blockchain: Blockchain) {
        do {
            let addressFromPublicKey = try blockchain.getAddressService().makeAddress(from: publicKey)
            validateTRUE(address: addressFromPublicKey, for: blockchain)
            
            XCTAssertEqual(address, addressFromPublicKey)
        } catch {
            XCTFail("__INVALID_ADDRESS__ BLOCKCHAIN FTOM PUBLIC KEY!")
        }
        
    }
    
    func validateTRUE(address: String, for blockchain: Blockchain) {
        XCTAssertTrue(TrustWalletAddressService.validate(address, for: blockchain), "__INVALID_ADDRESS__ FROM TW ADDRESS SERVICE")
        XCTAssertTrue(validate(address, for: blockchain), "__INVALID_ADDRESS__ FROM OWN ADDRESS SERVICE")
    }
    
    func validateFALSE(address: String, for blockchain: Blockchain) {
        XCTAssertFalse(TrustWalletAddressService.validate(address, for: blockchain))
        XCTAssertFalse(validate(address, for: blockchain))
    }
    
    // MARK: - Private Implementation
    
    private func validate(_ address: String, for blockchain: Blockchain) -> Bool {
        blockchain.getAddressService().validate(address)
    }
    
}
