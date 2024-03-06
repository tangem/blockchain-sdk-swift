//
//  RadiantNentworkProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 05.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Adapter for existing BlockBookUtxoProvider
final class RadiantNetworkProvider: BitcoinNetworkProvider {
    private let blockBookUtxoProvider: BlockBookUtxoProvider
    
    init(blockBookUtxoProvider: BlockBookUtxoProvider) {
        self.blockBookUtxoProvider = blockBookUtxoProvider
    }
    
    var host: String {
        blockBookUtxoProvider.host
    }
    
    var supportsTransactionPush: Bool {
        blockBookUtxoProvider.supportsTransactionPush
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        blockBookUtxoProvider.getInfo(address: addAddressPrefixIfNeeded(address))
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        blockBookUtxoProvider.executeRequest(
            .fees(NodeRequest.estimateFeeRequest(method: "estimatefee")),
            responseType: NodeEstimateFeeResponse.self
        )
        .tryMap { [weak self] response in
            guard let self else {
                throw WalletError.empty
            }
            
            return try blockBookUtxoProvider.convertFeeRate(response.result)
        }.map { fee in
            // fee for BCH is constant
            BitcoinFee(minimalSatoshiPerByte: fee, normalSatoshiPerByte: fee, prioritySatoshiPerByte: fee)
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        blockBookUtxoProvider.executeRequest(
            .sendNode(NodeRequest.sendRequest(signedTransaction: transaction)),
            responseType: SendResponse.self
        )
        .map { $0.result }
        .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        blockBookUtxoProvider.push(transaction: transaction)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        blockBookUtxoProvider.getSignatureCount(address: address)
    }
    
    private func addAddressPrefixIfNeeded(_ address: String) -> String {
        return address
    }
}
