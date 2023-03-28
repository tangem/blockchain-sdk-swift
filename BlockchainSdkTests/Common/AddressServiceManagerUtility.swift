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
    
    func validate(_ address: String, for blockchain: Blockchain) -> Bool {
        blockchain.getAddressService().validate(address)
    }
    
    func validateTRUE(address: String, for blockchain: Blockchain) {
        XCTAssertTrue(TrustWalletAddressService.validate(address, for: blockchain))
        XCTAssertTrue(validate(address, for: blockchain))
    }
    
    func validateFALSE(address: String, for blockchain: Blockchain) {
        XCTAssertFalse(TrustWalletAddressService.validate(address, for: blockchain))
        XCTAssertFalse(validate(address, for: blockchain))
    }
    
}
