//
//  RavencoinMultiNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 05.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class RavencoinMultiNetworkProvider: MultiNetworkProvider {
    var currentProviderIndex: Int = 0
    let providers: [RavencoinNetworkProvider]
    
    init(isTestnet: Bool, configuration: NetworkProviderConfiguration) {
        if isTestnet {
            providers = [RavencoinNetworkProvider(
                host: "https://testnet.ravencoin.org/api/",
                provider: NetworkProvider<RavencoinTarget>(configuration: configuration)
            )]
        } else {
            let hosts = ["https://api.ravencoin.org/api/", "https://ravencoin.network/api"]
            providers = hosts.map { host in
                RavencoinNetworkProvider(
                    host: host,
                    provider: NetworkProvider<RavencoinTarget>(configuration: configuration)
                )
            }
        }
    }
}

// MARK: - BitcoinNetworkProvider

extension RavencoinMultiNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        providerPublisher { provider in
            Publishers.CombineLatest3(
                provider.getWalletInfo(address: address),
                provider.getTransactions(address: address),
                provider.getUTXO(address: address)
            ).map { wallet, transactions, outputs -> BitcoinResponse in
                let unspentOutputs = outputs.map { utxo in
                    BitcoinUnspentOutput(transactionHash: utxo.txid,
                                         outputIndex: utxo.vout,
                                         amount: UInt64(utxo.satoshis),
                                         outputScript: utxo.scriptPubKey)
                }
                
                return BitcoinResponse(
                    balance: wallet.balance ?? 0,
                    hasUnconfirmed: wallet.unconfirmedTxApperances != 0,
                    pendingTxRefs: [], // TBD
                    unspentOutputs: unspentOutputs
                )
            }
            .eraseToAnyPublisher()
        }
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        providerPublisher { provider in
            provider.getFeeRateByBite(blocks: 10)
                .map { perByte in
                    let satoshi = perByte * pow(10, 8) // TODO: Change on decimalValue
                    let minRate = satoshi
                    let normalRate = satoshi * 12 / 10
                    let priorityRate = satoshi * 15 / 10
                    
                    return BitcoinFee(
                        minimalSatoshiPerByte: minRate,
                        normalSatoshiPerByte: normalRate,
                        prioritySatoshiPerByte: priorityRate
                    )
                }
                .eraseToAnyPublisher()
        }
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider.send(transaction: RavencoinRawTransaction.Request(rawtx: transaction))
                .map { $0.txid }
                .eraseToAnyPublisher()
        }
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        .anyFail(error: BlockchainSdkError.networkProvidersNotSupportsRbf)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        .anyFail(error: BlockchainSdkError.notImplemented)
    }
}
