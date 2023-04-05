//
//  RavencoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

/// Documentation:
/// https://github.com/RavenProject/Ravencoin/blob/master/doc/REST-interface.md
/// https://github.com/RavenDevKit/insight-api

/// Hosts: Will move to assembly
/// https://api.ravencoin.org/api/
/// https://ravencoin.network/api/
/// Testnet:
/// https://testnet.ravencoin.org/api/
class RavencoinNetworkProvider: HostProvider {
    let host: String
    let provider: NetworkProvider<RavencoinTarget>
    
    init(host: String, provider: NetworkProvider<RavencoinTarget>) {
        self.host = host
        self.provider = provider
    }
}

// MARK: - BitcoinNetworkProvider

extension RavencoinNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers.CombineLatest3(
            getWalletInfo(address: address),
            getTransactions(address: address),
            getUTXO(address: address)
        ).map { wallet, transactions, outputs -> BitcoinResponse in
            let unspentOutputs = outputs.map { utxo in
                BitcoinUnspentOutput(transactionHash: utxo.txid,
                                     outputIndex: utxo.vout,
                                     amount: UInt64(utxo.satoshis),
                                     outputScript: utxo.scriptPubKey)
            }
            
            print("transactions", transactions)
            
            return BitcoinResponse(
                    balance: wallet.balance ?? 0,
                    hasUnconfirmed: wallet.unconfirmedTxApperances != 0,
                    pendingTxRefs: [], // TBD
                    unspentOutputs: unspentOutputs
                )
            }
        .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        getFeeRateByBite(blocks: 10)
            .map { perByte in
                let satoshi = perByte * pow(10, 8) // TODO: Change on decimalValue
                let minRate = satoshi
                let normalRate = satoshi * 12 / 10
                let priorityRate = satoshi * 12 / 10

                return BitcoinFee(
                    minimalSatoshiPerByte: perByte,
                    normalSatoshiPerByte: perByte,
                    prioritySatoshiPerByte: perByte
                )
            }
            .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        send(transaction: RavencoinRawTransaction.Request(rawtx: transaction))
            .map { $0.txid }
            .eraseToAnyPublisher()
    }
    // fees
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        .anyFail(error: BlockchainSdkError.networkProvidersNotSupportsRbf)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        .anyFail(error: BlockchainSdkError.notImplemented)
    }
}

// MARK: - Private

private extension RavencoinNetworkProvider {
    func getWalletInfo(address: String) -> AnyPublisher<RavencoinWalletInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .wallet(address: address)))
            .map(RavencoinWalletInfo.self)
            .eraseError()
    }
    
    func getTransactions(address: String) -> AnyPublisher<[RavencoinTransactionInfo], Error> {
        provider
            .requestPublisher(.init(host: host, target: .transactions(address: address)))
            .map([RavencoinTransactionInfo].self)
            .eraseError()
    }
    
    func getUTXO(address: String) -> AnyPublisher<[RavencoinWalletUTXO], Error> {
        provider
            .requestPublisher(.init(host: host, target: .utxo(address: address)))
            .map([RavencoinWalletUTXO].self)
            .eraseError()
    }
    
    func getFeeRateByBite(blocks: Int) -> AnyPublisher<Decimal, Error> {
        provider
            .requestPublisher(.init(host: host, target: .fees(request: .init(nbBlocks: blocks))))
            .mapJSON(failsOnEmptyData: true)
            .compactMap { $0 as? [String: Any] }
            .compactMap { $0["\(blocks)"] as? Decimal } // Get rate per kilobyte
            .map { $0 / 1024 }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getTxInfo(transactionId: String) -> AnyPublisher<RavencoinTransactionInfo, Error> {
        provider
            .requestPublisher(.init(host: host, target: .transaction(id: transactionId)))
            .map(RavencoinTransactionInfo.self)
            .eraseError()
    }
    
    func send(transaction: RavencoinRawTransaction.Request) -> AnyPublisher<RavencoinRawTransaction.Response, Error> {
        provider
            .requestPublisher(.init(host: host, target: .send(transaction: transaction)))
            .map(RavencoinRawTransaction.Response.self)
            .eraseToAnyPublisher()
            .eraseError()
    }
}
