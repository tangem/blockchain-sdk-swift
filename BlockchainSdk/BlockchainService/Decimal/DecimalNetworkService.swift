//
//  DecimalNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 29.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

final class DecimalNetworkService: EthereumNetworkService {
    
    private let addressConverter = DecimalBlockchainAddressConverter()
    
    // MARK: - Override
    
    override func getInfo(address: String, tokens: [Token]) -> AnyPublisher<EthereumInfoResponse, Error> {
        do {
            let convertedAddress = try convertAddressIfNeeded(address: address)
            return super.getInfo(address: convertedAddress, tokens: tokens)
        } catch {
            return .anyFail(error: WalletError.empty)
        }
    }
    
    override func getFee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumFeeResponse, Error> {
        do {
            let fromConvertedAddress = try convertAddressIfNeeded(address: from)
            let toConvertedAddress = try convertAddressIfNeeded(address: to)
            return super.getFee(to: toConvertedAddress, from: fromConvertedAddress, value: value, data: data)
        } catch {
            return .anyFail(error: WalletError.failedToGetFee)
        }
    }
    
    override func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        do {
            let convertedAddress = try convertAddressIfNeeded(address: address)
            return super.getBalance(convertedAddress)
        } catch {
            return .anyFail(error: WalletError.failedToGetFee)
        }
    }
    
    override func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        do {
            let convertedAddress = try convertAddressIfNeeded(address: address)
            return super.getTxCount(convertedAddress)
        } catch {
            return .anyFail(error: WalletError.empty)
        }
    }
    
    override func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        do {
            let fromConvertedAddress = try convertAddressIfNeeded(address: from)
            let toConvertedAddress = try convertAddressIfNeeded(address: to)
            return super.getGasLimit(to: toConvertedAddress, from: fromConvertedAddress, value: value, data: data)
        } catch {
            return .anyFail(error: WalletError.empty)
        }
    }
    
    override func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token : Decimal], Error> {
        do {
            let convertedAddress = try convertAddressIfNeeded(address: address)
            return super.getTokensBalance(convertedAddress, tokens: tokens)
        } catch {
            return .anyFail(error: WalletError.empty)
        }
    }
    
    override func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        do {
            let convertedAddress = try convertAddressIfNeeded(address: address)
            return super.getSignatureCount(address: convertedAddress)
        } catch {
            return .anyFail(error: WalletError.empty)
        }
    }
    
    override func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        do {
            let convertedAddress = try convertAddressIfNeeded(address: address)
            return super.getPendingTxCount(convertedAddress)
        } catch {
            return .anyFail(error: WalletError.empty)
        }
    }
    
}

// MARK: - Private Implementation

extension DecimalNetworkService {
    private func convertAddressIfNeeded(address: String) throws -> String {
        try addressConverter.convertErcAddressToDscAddress(addressHex: address)
    }
}
