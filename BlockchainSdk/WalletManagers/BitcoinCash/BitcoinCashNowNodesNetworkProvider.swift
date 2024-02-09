//
//  BitcoinCashNowNodesNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 08.02.2024.
//

import Foundation
import Combine

final class BitcoinCashNowNodesNetworkProvider: BitcoinNetworkProvider {
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
        let prefix = "bitcoincash:"
        let address = address.hasPrefix(prefix) ? address : prefix + address
        return blockBookUtxoProvider.getInfo(address: address)
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        // Number of blocks we want the transaction to be confirmed in.
        // The lower the number the bigger the fee returned by 'estimatesmartfee'.
        let confirmationBlocks = [8, 4, 1]
        
        return blockBookUtxoProvider.mapBitcoinFee(confirmationBlocks.map(getFeeRatePerByte(for:)))
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        let response: AnyPublisher<NodeSendResponse, Error> = blockBookUtxoProvider.executeRequest(
            .sendTransaction(NodeRequest.sendRequest(signedTransaction: transaction))
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
    
    private func getFeeRatePerByte(for confirmationBlocks: Int) -> AnyPublisher<Decimal, Error> {
        let response: AnyPublisher<NodeEstimateFeeResponse, Error> = blockBookUtxoProvider.executeRequest(
            .fees(NodeRequest.estimateFeeRequest(method: "estimatefee"))
        )
        
        return response.tryMap { [weak self] response in
            guard let self else {
                throw WalletError.empty
            }
            
            return try blockBookUtxoProvider.convertFee(response.result)
        }.eraseToAnyPublisher()
    }
}
