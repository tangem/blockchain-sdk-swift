//
//  KaspaNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkProvider {
    var host: String {
        url.hostOrUnknown
    }
    
    var supportsTransactionPush: Bool {
        false
    }
    
    private let url: URL
    private let blockchain: Blockchain
    private let provider: NetworkProvider<KaspaTarget>
    
    init(url: URL, blockchain: Blockchain, networkConfiguration: NetworkProviderConfiguration) {
        self.url = url
        self.blockchain = blockchain
        self.provider = NetworkProvider<KaspaTarget>(configuration: networkConfiguration)
    }
    
    private func balance(address: String) -> AnyPublisher<KaspaBalanceResponse, Error> {
        requestPublisher(for: .balance(address: address))
    }
    
    private func utxos(address: String) -> AnyPublisher<[KaspaUnspentOutputResponse], Error> {
        requestPublisher(for: .utxos(address: address))
    }
    
    private func requestPublisher<T: Codable>(for request: KaspaTarget.Request) -> AnyPublisher<T, Error> {
        return provider.requestPublisher(KaspaTarget(request: request, baseURL: url))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(T.self)
            .mapError { moyaError in
                if case .objectMapping = moyaError {
                    return WalletError.failedToParseNetworkResponse
                }
                return moyaError
            }
            .eraseToAnyPublisher()
    }
}

extension KaspaNetworkProvider: BitcoinNetworkProvider {
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers.Zip(balance(address: address), utxos(address: address))
            .tryMap { [weak self] (balance, utxos) in
                guard let self else { throw WalletError.empty }
                
                let unspentOutputs: [BitcoinUnspentOutput] = utxos.compactMap {
                    guard
                        let amount = UInt64($0.utxoEntry.amount)
                    else {
                        return nil
                    }
                    
                    let d = Data(hex: $0.utxoEntry.scriptPublicKey.scriptPublicKey)
                    print(d.count)
                    print(d[0], d[d.count - 1])
                    
                    return BitcoinUnspentOutput(
                        transactionHash: $0.outpoint.transactionId,
                        outputIndex: $0.outpoint.index,
                        amount: amount,
                        outputScript: $0.utxoEntry.scriptPublicKey.scriptPublicKey
                    )
                }
                
                return BitcoinResponse(
                    balance: Decimal(integerLiteral: balance.balance) / self.blockchain.decimalValue,
                    hasUnconfirmed: false,
                    pendingTxRefs: [],
                    unspentOutputs: unspentOutputs
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        // TODO
        .anyFail(error: WalletError.empty)
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        .anyFail(error: WalletError.empty)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        .anyFail(error: WalletError.empty)
    }
}
