//
//  BitcoinCashNowNodesNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 08.02.2024.
//

import Foundation
import Combine

/// Adapter for existing BlockBookUtxoProvider
final class BitcoinCashNowNodesNetworkProvider: BitcoinNetworkProvider {
    private let blockBookUtxoProvider: BlockBookUtxoProvider
    private let addressService: AddressService
    
    init(blockBookUtxoProvider: BlockBookUtxoProvider, addressService: AddressService) {
        self.blockBookUtxoProvider = blockBookUtxoProvider
        self.addressService = addressService
    }
    
    var host: String {
        blockBookUtxoProvider.host
    }
    
    var supportsTransactionPush: Bool {
        blockBookUtxoProvider.supportsTransactionPush
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        if let addressService = addressService as? BitcoinCashAddressService, addressService.isLegacy(address) {
            return blockBookUtxoProvider.getInfo(address: address)
        } else {
            let prefix = "bitcoincash:"
            return blockBookUtxoProvider.getInfo(address: address.hasPrefix(prefix) ? address : prefix + address)
        }
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        let response: AnyPublisher<NodeEstimateFeeResponse, Error> = blockBookUtxoProvider.executeRequest(
            .fees(NodeRequest.estimateFeeRequest(method: "estimatefee"))
        )
        
        return response
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
        let response: AnyPublisher<SendResponse, Error> = blockBookUtxoProvider.executeRequest(
            .sendNode(NodeRequest.sendRequest(signedTransaction: transaction))
        )
        
        return response
            .map { $0.result }
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        blockBookUtxoProvider.push(transaction: transaction)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        blockBookUtxoProvider.getSignatureCount(address: address)
    }
}
