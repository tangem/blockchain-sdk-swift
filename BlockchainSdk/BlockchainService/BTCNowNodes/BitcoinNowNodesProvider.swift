//
//  NowNodesBTCProvider.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BitcoinNowNodesProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    var host: String {
        ""
    }

    private let apiKey: String
    private let provider: NetworkProvider<BitcoinNowNodesTarget>
    
    init(configuration: NetworkProviderConfiguration, apiKey: String) {
        self.apiKey = apiKey
        self.provider = NetworkProvider<BitcoinNowNodesTarget>(configuration: configuration)
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers
            .Zip(addressData(walletAddress: address), unspentTxData(walletAddress: address))
            .tryMap { (addressResponse, unspentTxResponse) in
                let unspentOutputs = unspentTxResponse.map { response in
                    BitcoinUnspentOutput(transactionHash: response.txid, outputIndex: response.vout, amount: UInt64(response.value) ?? 0, outputScript: "")
                }
                
                addressResponse.transactions.map { tx in
                    if tx.confirmations == 0 {
                        PendingTransaction(hash: tx.hex, destination: "", value: Decimal(string: tx.value) ?? 0, source: addressResponse.address, fee: Decimal(string: tx.fees), date: <#T##Date#>, isIncoming: <#T##Bool#>, transactionParams: <#T##TransactionParams?#>)
                    }
                }
                
                return BitcoinResponse(balance: Decimal(string: addressResponse.balance) ?? 0, hasUnconfirmed: addressResponse.unconfirmedTxs != 0, pendingTxRefs: [], unspentOutputs: unspentOutputs)
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        provider
            .requestPublisher(BitcoinNowNodesTarget(endpoint: .fees, apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockchainInfoFeeResponse.self)
            .tryMap { response throws -> BitcoinFee in
                let min = Decimal(response.regular)
                let normal = (Decimal(response.regular) * Decimal(1.2)).rounded(roundingMode: .down)
                let priority = Decimal(response.priority)
                
                return BitcoinFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: normal, prioritySatoshiPerByte: priority)
            }
            .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        provider
            .requestPublisher(BitcoinNowNodesTarget(endpoint: .send(txHex: transaction), apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        send(transaction: transaction)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> { // TODO: ??
        Just(0)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func addressData(walletAddress: String) -> AnyPublisher<BitcoinNowNodesAddressResponse, Error> {
        provider
            .requestPublisher(BitcoinNowNodesTarget(endpoint: .address(walletAddress: walletAddress), apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BitcoinNowNodesAddressResponse.self)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func unspentTxData(walletAddress: String) -> AnyPublisher<[BitcoinNowNodesUnspentTxResponse], Error> {
        provider
            .requestPublisher(BitcoinNowNodesTarget(endpoint: .txUnspents(walletAddress: walletAddress), apiKey: apiKey))
            .filterSuccessfulStatusAndRedirectCodes()
            .map([BitcoinNowNodesUnspentTxResponse].self)
            .eraseError()
            .eraseToAnyPublisher()
    }
}
