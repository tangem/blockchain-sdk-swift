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
    private let addressConverter = DecimalBlockchainAddressConverter()
    
    override func getInfo(address: String, tokens: [Token], _ completion: @escaping (Result<Void, Error>) -> Void) {
        let convertedDestinationAddress = convertAddressIfNeeded(destinationAddress: address)
        super.getInfo(address: convertedDestinationAddress, tokens: tokens, completion)
    }
    
    override func getFee(to: String, from: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        let fromConvertedAddress = convertAddressIfNeeded(destinationAddress: from)
        let toConvertedAddress = convertAddressIfNeeded(destinationAddress: to)
        return super.getFee(to: toConvertedAddress, from: fromConvertedAddress, value: value, data: data)
    }
    
    // MARK: - Private Implementation

    private func convertAddressIfNeeded(destinationAddress: String) -> String {
        addressConverter.convertDscAddressToErcAddress(addressHex: destinationAddress) ?? destinationAddress
    }
    
}

