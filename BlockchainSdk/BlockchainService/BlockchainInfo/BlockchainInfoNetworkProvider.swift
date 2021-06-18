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
    
    let provider = MoyaProvider<BlockchainInfoTarget>(plugins: [NetworkLoggerPlugin()])
    
    var host: String {
        BlockchainInfoTarget.address(address: "", offset: nil).baseURL.hostOrUnknown
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        addressUnspentsData(address)
            .tryMap {(addressResponse, unspentsResponse) throws -> (BitcoinResponse, [UInt64]) in
                guard let balance = addressResponse.finalBalance,
                      let txs = addressResponse.transactions else {
                    throw WalletError.failedToGetFee
                }
                
                // Unspents in Blockchain.info have 0 confirmations when transaction that used parent unspent currently in Mempool.
                // For this case we cannot use this unspent neither for new transaction nor for replacing old transaction
                var utxs: [BitcoinUnspentOutput] = unspentsResponse.unspentOutputs?.compactMap { utxo -> BitcoinUnspentOutput?  in
                    guard let hash = utxo.hash,
                          let outputIndex = utxo.outputIndex,
                          let amount = utxo.amount,
                          let script = utxo.outputScript,
                          utxo.confirmations ?? 0 > 0
                    else {
                        return nil
                    }
                    
                    let btx = BitcoinUnspentOutput(transactionHash: hash, outputIndex: outputIndex, amount: amount, outputScript: script)
                    return btx
                } ?? []
                
                var missingUnspents: [UInt64] = []
                let decimalValue = Blockchain.bitcoin(testnet: false).decimalValue
//                let pendingBasicTxs = addressResponse.transactions?.filter { $0.blockHeight == nil }
//                    .compactMap { $0.toBasicTxData(userAddress: address, decimalValue: decimalValue) }
                let pendingTxs: [PendingTransaction] = addressResponse.transactions?.filter { $0.blockHeight == nil }.compactMap { tx in
                    
                    guard let pendingTx = tx.toPendingTx(userAddress: address, decimalValue: decimalValue) else { return nil }
                    
                    if !pendingTx.isIncoming {
                        // We must find unspent outputs if we encounter outgoing transaction,
                        // because Blockchain.info won't return this unspents in unspents request
                        let addressInputs = tx.inputs?.filter { $0.previousOutput?.address == address } ?? []
                        addressInputs.forEach { input in
                            // Blockchain.info doesn't return transaction hash like Blockcypher of Blockchair
                            // Because of that we must to search tx by index
                            guard let txIndex = input.previousOutput?.txIndex else { return }
                            
                            guard
                                let transaction = addressResponse.transactions?.first(where: { txIndex == $0.txIndex }),
                                let unspent = transaction.findUnspentOutput(for: address)
                            else {
                                // If transaction with specified tx index wasn't found, we must request this specific tx from API
                                missingUnspents.append(txIndex)
                                return
                            }
                            
                            
                            utxs.append(unspent)
                        }
                    }
                    
                    return pendingTx
                } ?? []
                let satoshiBalance = Decimal(balance) / decimalValue
                let hasUnconfirmed = txs.first(where: { ($0.blockHeight ?? 0) == 0  }) != nil
                return (BitcoinResponse(balance: satoshiBalance, hasUnconfirmed: hasUnconfirmed, pendingTxRefs: pendingTxs, unspentOutputs: utxs), missingUnspents)
            }
            .flatMap { [unowned self] (btcResponse: BitcoinResponse, missingUnspentsIndices: [UInt64]) -> AnyPublisher<BitcoinResponse, Error> in
                guard missingUnspentsIndices.count > 0 else {
                    return .justWithError(output: btcResponse)
                }
                
                return Publishers.MergeMany(
                    missingUnspentsIndices.map { self.getTransaction(with: $0) }
                )
                .collect()
                .map { missingTxs -> BitcoinResponse in
                    let unspents = missingTxs.compactMap { $0.findUnspentOutput(for: address) }
                    var finalUnspents = btcResponse.unspentOutputs
                    unspents.forEach { finalUnspents.appendIfNotContain($0) }
                    
                    return BitcoinResponse(balance: btcResponse.balance, hasUnconfirmed: btcResponse.hasUnconfirmed, pendingTxRefs: btcResponse.pendingTxRefs, unspentOutputs: finalUnspents)
                }
                .eraseToAnyPublisher()
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
    
    func getTransaction(with hash: String) -> AnyPublisher<BlockchainInfoTransaction, Error> {
        provider
            .requestPublisher(.transaction(hash: hash))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockchainInfoTransaction.self)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func getTransaction(with index: UInt64) -> AnyPublisher<BlockchainInfoTransaction, Error> {
        getTransaction(with: "\(index)")
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
