//
//  XDCNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt

final class XDCNetworkService: EthereumNetworkService {
    private let addressConverter = XDCAddressConverter()

    // MARK: - Override

    override func getInfo(address: String, tokens: [Token]) -> AnyPublisher<EthereumInfoResponse, Error> {
        let convertedAddress = addressConverter.convertToETHAddress(address)
        return super.getInfo(address: convertedAddress, tokens: tokens)
    }

    override func getEIP1559Fee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumEIP1559FeeResponse, Error> {
        let fromConvertedAddress = addressConverter.convertToETHAddress(from)
        let toConvertedAddress = addressConverter.convertToETHAddress(to)
        return super.getEIP1559Fee(to: toConvertedAddress, from: fromConvertedAddress, value: value, data: data)
    }

    override func getLegacyFee(to: String, from: String, value: String?, data: String?) -> AnyPublisher<EthereumLegacyFeeResponse, Error> {
        let fromConvertedAddress = addressConverter.convertToETHAddress(from)
        let toConvertedAddress = addressConverter.convertToETHAddress(to)
        return super.getLegacyFee(to: toConvertedAddress, from: fromConvertedAddress, value: value, data: data)
    }

    override func getBalance(_ address: String) -> AnyPublisher<Decimal, Error> {
        let convertedAddress = addressConverter.convertToETHAddress(address)
        return super.getBalance(convertedAddress)
    }

    override func getTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        let convertedAddress = addressConverter.convertToETHAddress(address)
        return super.getTxCount(convertedAddress)
    }

    override func getGasLimit(to: String, from: String, value: String?, data: String?) -> AnyPublisher<BigUInt, Error> {
        let fromConvertedAddress = addressConverter.convertToETHAddress(from)
        let toConvertedAddress = addressConverter.convertToETHAddress(to)
        return super.getGasLimit(to: toConvertedAddress, from: fromConvertedAddress, value: value, data: data)
    }

    override func getTokensBalance(_ address: String, tokens: [Token]) -> AnyPublisher<[Token : Decimal], Error> {
        let convertedAddress = addressConverter.convertToETHAddress(address)
        return super.getTokensBalance(convertedAddress, tokens: tokens)
    }

    override func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        let convertedAddress = addressConverter.convertToETHAddress(address)
        return super.getSignatureCount(address: convertedAddress)
    }

    override func getPendingTxCount(_ address: String) -> AnyPublisher<Int, Error> {
        let convertedAddress = addressConverter.convertToETHAddress(address)
        return super.getPendingTxCount(convertedAddress)
    }
}
