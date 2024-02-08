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
    private let config: BlockBookConfig
    private let provider: NetworkProvider<BlockBookTarget>
    
    init(
        blockBookUtxoProvider: BlockBookUtxoProvider,
        config: BlockBookConfig,
        networkConfiguration: NetworkProviderConfiguration
    ) {
        self.blockBookUtxoProvider = blockBookUtxoProvider
        self.config = config
        self.provider = NetworkProvider(configuration: networkConfiguration)
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
        
        return Publishers.MergeMany(confirmationBlocks.map {
            getFeeRatePerByte(for: $0)
        })
        .collect()
        .map { $0.sorted() }
        .tryMap { fees -> BitcoinFee in
            guard fees.count == confirmationBlocks.count else {
                throw BlockchainSdkError.failedToLoadFee
            }
            
            return BitcoinFee(
                minimalSatoshiPerByte: fees[0],
                normalSatoshiPerByte: fees[1],
                prioritySatoshiPerByte: fees[2]
            )
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        provider
            .requestPublisher(target(for: .sendTransaction(SendTransactionRequest(signedTransaction: transaction))))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockBookSendResponse.self)
            .eraseError()
            .map { $0.result }
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        blockBookUtxoProvider.push(transaction: transaction)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        blockBookUtxoProvider.getSignatureCount(address: address)
    }
    
    private func target(for request: BlockBookTarget.Request) -> BlockBookTarget {
        BlockBookTarget(request: request, config: config, blockchain: .bitcoinCash)
    }
    
    private func getFeeRatePerByte(for confirmationBlocks: Int) -> AnyPublisher<Decimal, Error> {
        provider
            .requestPublisher(target(for: .fees(method: "estimatefee")))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BitcoinCashGetFeeResponse.self)
            .tryMap { [weak self] response in
                guard let self else {
                    throw WalletError.empty
                }
                
                return try blockBookUtxoProvider.mapFee(response.result)
            }
            .eraseToAnyPublisher()
    }
}
