//
//  KaspaNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
class KaspaNetworkService: MultiNetworkProvider {
    let providers: [KaspaNetworkProvider]
    var currentProviderIndex: Int = 0
    private let blockchain: Blockchain
    
    init(providers: [KaspaNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        balance(address: address)
            .zip(utxos(address: address))
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
            .retry(2)
            .eraseToAnyPublisher()
    }
    
    func send(transaction: KaspaTransactionRequest) -> AnyPublisher<KaspaTransactionResponse, Error>{
        providerPublisher {
            $0.send(transaction: transaction)
        }
    }
    
    private func balance(address: String) -> AnyPublisher<KaspaBalanceResponse, Error> {
        providerPublisher {
            $0.balance(address: address)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
    
    private func utxos(address: String) -> AnyPublisher<[KaspaUnspentOutputResponse], Error> {
        providerPublisher {
            $0.utxos(address: address)
                .retry(2)
                .eraseToAnyPublisher()
        }
    }
}
