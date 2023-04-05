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
    let blockchain: Blockchain
    let provider: NetworkProvider<RavencoinTarget>
    
    init(host: String, blockchain: Blockchain, provider: NetworkProvider<RavencoinTarget>) {
        self.host = host
        self.blockchain = blockchain
        self.provider = provider
    }
}

// MARK: - BitcoinNetworkProvider

extension RavencoinNetworkProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers.Zip(getWalletInfo(address: address), getUTXO(address: address))
            .map { wallet, outputs -> BitcoinResponse in
                let unspentOutputs = outputs.map { utxo in
                    BitcoinUnspentOutput(transactionHash: utxo.txid,
                                         outputIndex: utxo.vout,
                                         amount: utxo.satoshis,
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
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        getFeeRatePerByte(blocks: 10)
            .tryMap { [weak self] perByte in
                guard let self else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let satoshi = perByte * self.blockchain.decimalValue
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
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        send(transaction: RavencoinRawTransaction.Request(rawtx: transaction))
            .map { $0.txid }
            .eraseToAnyPublisher()
    }
    
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
            .map(RavencoinBaseTransactionInfo.self)
            .map { $0.txs }
            .eraseToAnyPublisher()
            .eraseError()
    }
    
    func getUTXO(address: String) -> AnyPublisher<[RavencoinWalletUTXO], Error> {
        provider
            .requestPublisher(.init(host: host, target: .utxo(address: address)))
            .map([RavencoinWalletUTXO].self)
            .eraseError()
    }
    
    func getFeeRatePerByte(blocks: Int) -> AnyPublisher<Decimal, Error> {
        provider
            .requestPublisher(.init(host: host, target: .fees(request: .init(nbBlocks: blocks))))
            .mapJSON(failsOnEmptyData: true)
            .tryMap { json throws -> Decimal in
                guard let json = json as? [String: Any],
                      let rate = json["\(blocks)"] as? Double else {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let ratePerKilobyte = Decimal(floatLiteral: rate)
                return ratePerKilobyte / 1024
            }
            .eraseToAnyPublisher()
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
