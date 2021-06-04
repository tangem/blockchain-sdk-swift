//
//  BlockchainInfoNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

class BlockchainInfoNetworkProvider: BitcoinNetworkProvider {
    func getTransaction(with hash: String) -> AnyPublisher<BitcoinTransaction, Error> {
        .anyFail(error: "Not implemented")
    }
    
    let provider = MoyaProvider<BlockchainInfoTarget>(plugins: [NetworkLoggerPlugin()])
    
    var host: String {
        BlockchainInfoTarget.address(address: "", offset: nil).baseURL.hostOrUnknown
    }
    
    var canPushTransaction: Bool { false }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        addressUnspentsData(address)
            .tryMap {(addressResponse, unspentsResponse) throws -> BitcoinResponse in
                guard let balance = addressResponse.finalBalance,
                      let txs = addressResponse.transactions else {
                    throw WalletError.failedToGetFee
                }
                
                let utxs: [BitcoinUnspentOutput] = unspentsResponse.unspentOutputs?.compactMap { utxo -> BitcoinUnspentOutput?  in
                    guard let hash = utxo.hash,
                          let outputIndex = utxo.outputIndex,
                          let amount = utxo.amount,
                          let script = utxo.outputScript else {
                        return nil
                    }
                    
                    let btx = BitcoinUnspentOutput(transactionHash: hash, outputIndex: outputIndex, amount: amount, outputScript: script)
                    return btx
                } ?? []
                
                let decimalValue = Blockchain.bitcoin(testnet: false).decimalValue
                let pendingTxs = addressResponse.transactions?.filter { $0.blockHeight == nil }
                    .map { $0.toBasicTxData(decimalValue: decimalValue) }
                let satoshiBalance = Decimal(balance) / decimalValue
                let hasUnconfirmed = txs.first(where: { ($0.blockHeight ?? 0) == 0  }) != nil
                return BitcoinResponse(balance: satoshiBalance, hasUnconfirmed: hasUnconfirmed, recentTransactions: pendingTxs, unspentOutputs: utxs)
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        provider.requestPublisher(.fees)
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
        provider.requestPublisher(.send(txHex: transaction))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        .anyFail(error: "Not supported")
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        let responseTransactionCap = 50
        var numberOfItems = 0
        var currentOffset = 0
        var loadedCount = 0
        
        let subject = CurrentValueSubject<Int, Error>(currentOffset)
        return subject
            .flatMap { [unowned self] offset -> AnyPublisher<BlockchainInfoAddressResponse, Error> in
                offset == 0 ?
                    self.addressData(address) :
                    self.addressData(address, transactionsOffset: offset)
            }
            .handleEvents(receiveOutput: { (response: BlockchainInfoAddressResponse) in
                let responseTxCount = response.transactions?.count ?? 0
                if currentOffset == 0 {
                    numberOfItems = response.transactionCount ?? 0
                    if numberOfItems > responseTxCount {
                        while currentOffset < numberOfItems {
                            currentOffset += responseTransactionCap
                            subject.send(currentOffset)
                        }
                    }
                }
                loadedCount += responseTxCount
                if loadedCount >= numberOfItems {
                    subject.send(completion: .finished)
                }
            })
            .map { $0.transactions ?? [] }
            .reduce([BlockchainInfoTransaction](), { $0 + $1 })
            .map { items in
                items.filter { ($0.balanceDif ?? 0) < 0 }.count
            }
            .eraseToAnyPublisher()
    }
    
    private func addressUnspentsData(_ address: String) -> AnyPublisher<(BlockchainInfoAddressResponse, BlockchainInfoUnspentResponse), Error> {
        Publishers.Zip(
            addressData(address),
            provider
                .requestPublisher(.unspents(address: address))
                .filterSuccessfulStatusAndRedirectCodes()
                .map(BlockchainInfoUnspentResponse.self)
                .tryCatch { error -> AnyPublisher<BlockchainInfoUnspentResponse, Error> in
                    if case let MoyaError.statusCode (response) = error {
                        let stringError = try response.mapString()
                        if stringError == "No free outputs to spend" {
                            return Just(BlockchainInfoUnspentResponse(unspentOutputs: []))
                                .setFailureType(to: Error.self)
                                .eraseToAnyPublisher()
                        } else {
                            throw stringError
                        }
                    } else {
                        throw error
                    }
                })
            .eraseToAnyPublisher()
    }
    
    private func addressData(_ address: String, transactionsOffset: Int? = nil) -> AnyPublisher<BlockchainInfoAddressResponse, Error> {
        provider
            .requestPublisher(.address(address: address, offset: transactionsOffset))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockchainInfoAddressResponse.self)
            .eraseError()
    }
}
