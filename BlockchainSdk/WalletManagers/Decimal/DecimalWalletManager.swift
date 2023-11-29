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
import BigInt

final class DecimalWalletManager: EthereumWalletManager {
    private let addressConverter = DecimalBlockchainAddressConverter()
    
    override func getInfo(address: String, tokens: [Token], _ completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let convertedDestinationAddress = try convertAddressIfNeeded(destinationAddress: address)
            super.getInfo(address: convertedDestinationAddress, tokens: tokens, completion)
        } catch {
            completion(.failure(WalletError.empty))
        }
    }
    
    override func getFee(to: String, from: String, value: String?, data: Data?) -> AnyPublisher<[Fee], Error> {
        do {
            let fromConvertedAddress = try convertAddressIfNeeded(destinationAddress: from)
            let toConvertedAddress = try convertAddressIfNeeded(destinationAddress: to)
            return super.getFee(to: toConvertedAddress, from: fromConvertedAddress, value: value, data: data)
        } catch {
            return .anyFail(error: WalletError.failedToGetFee)
        }
    }
    
    override func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        do {
            let fromConvertedAddress = try convertAddressIfNeeded(destinationAddress: from)
            let toConvertedAddress = try convertAddressIfNeeded(destinationAddress: to)
            return super.getGasLimit(to: toConvertedAddress, from: fromConvertedAddress, value: value, data: data)
        } catch {
            return .anyFail(error: WalletError.failedToGetFee)
        }
    }
    
    // MARK: - Private Implementation

    private func convertAddressIfNeeded(destinationAddress: String) throws -> String {
        try addressConverter.convertDscAddressToErcAddress(addressHex: destinationAddress)
    }
    
}

