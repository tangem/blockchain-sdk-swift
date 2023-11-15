//
//  DecimalWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

final class DecimalWalletManager: EthereumWalletManager {
    
    override func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        super.sign(transaction, signer: signer)
    }
    
    // MARK: - Private Implementation

    private func convertAddress(destinationAddress: String) -> String {
        return DecimalUtils().convertDscAddressToErcAddress(addressHex: destinationAddress) ?? destinationAddress
    }
    
}

