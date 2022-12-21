//
//  BlockBookProvider.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BlockBookProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    
    var host: String {
        serviceProvider.host
    }
    
    private let blockchain: Blockchain
    private let serviceProvider: BlockBookService
    private let apiKey: String
    private let provider: NetworkProvider<BlockBookTarget>
    
    init(blockchain: Blockchain, serviceProvider: BlockBookService, configuration: NetworkProviderConfiguration, apiKey: String) {
        self.blockchain = blockchain
        self.serviceProvider = serviceProvider
        self.apiKey = apiKey
        self.provider = NetworkProvider<BlockBookTarget>(configuration: configuration)
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers
            .Zip(addressData(walletAddress: address), unspentTxData(walletAddress: address))
            .tryMap { (addressResponse, unspentTxResponse) in
                let transactions = addressResponse.transactions ?? []
                
                let outputScript = transactions
                    .compactMap { transaction in
                        transaction.vout.first {
                            $0.addresses.contains(address)
                        }
                    }
                    .map { vout in
                        vout.hex
                    }
                    .first
                
                let unspentOutputs = transactions
                    .map { response in
                        var outputs = [BitcoinUnspentOutput]()
                        let filteredResponse = response.vout.filter({ $0.addresses.contains(address) && $0.spent == nil })
                        filteredResponse.forEach {
                            guard let outputScript = outputScript else { return }
                            outputs.append(BitcoinUnspentOutput(transactionHash: response.txid, outputIndex: $0.n, amount: UInt64($0.value) ?? 0, outputScript: outputScript))
                        }
                        return outputs
                    }
                    .reduce([BitcoinUnspentOutput](), +)
                
                let pendingRefs = transactions
                    .filter({ $0.confirmations == 0 })
                    .map { tx in
                        var source: String = .unknown
                        var destination: String = .unknown
                        var value: Decimal?
                        var isIncoming: Bool = false
                        
                        if let _ = tx.vin.first(where: { $0.addresses.contains(address) }), let txDestination = tx.vout.first(where: { $0.addresses.contains(address) }) {
                            destination = txDestination.addresses.first ?? .unknown
                            source = address
                            value = Decimal(string: txDestination.value) ?? 0
                        } else if let txDestination = tx.vout.first(where: { $0.addresses.contains(address) }), let txSources = tx.vin.first(where: { $0.addresses.contains(address) }) {
                            isIncoming = true
                            destination = address
                            source = txSources.addresses.first ?? .unknown
                            value = Decimal(string: txDestination.value) ?? 0
                        }
                        
                        let bitcoinInputs: [BitcoinInput] = tx.vin.compactMap { input in
                            guard
                                let hex = input.hex,
                                let sequence = input.sequence
                            else {
                                return nil
                            }
                            
                            return BitcoinInput(sequence: sequence, address: address, outputIndex: input.n, outputValue: 0, prevHash: hex)
                        }
                        
                        return PendingTransaction(hash: tx.hex,
                                                  destination: destination,
                                                  value: (value ?? 0) / Blockchain.bitcoin(testnet: false).decimalValue,
                                                  source: source,
                                                  fee: Decimal(string: tx.fees),
                                                  date: Date(), // ???
                                                  isIncoming: isIncoming,
                                                  transactionParams: BitcoinTransactionParams(inputs: bitcoinInputs))
                    }
                
                let balance = (Decimal(string: addressResponse.balance) ?? 0) / self.blockchain.decimalValue
                
                return BitcoinResponse(balance: balance, hasUnconfirmed: addressResponse.unconfirmedTxs != 0, pendingTxRefs: pendingRefs, unspentOutputs: unspentOutputs)
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        provider
            .requestPublisher(target(for: .fees))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockBookFeeResponse.self)
            .map(\.result.feerate)
            .map { [weak self] in
                return Decimal($0) * (self?.blockchain.decimalValue ?? 0)
            }
            .tryMap { feeRate throws -> BitcoinFee in
                let min = (Decimal(0.8) * feeRate).rounded(roundingMode: .down)
                let normal = feeRate
                let max = (Decimal(1.2) * feeRate).rounded(roundingMode: .down)
                
                return BitcoinFee(minimalSatoshiPerByte: min, normalSatoshiPerByte: normal, prioritySatoshiPerByte: max)
            }
            .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        provider
            .requestPublisher(target(for: .send(txHex: transaction)))
            .filterSuccessfulStatusAndRedirectCodes()
            .mapNotEmptyString()
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    func push(transaction: String) -> AnyPublisher<String, Error> {
        send(transaction: transaction)
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        addressData(walletAddress: address)
            .tryMap {
                $0.txs + $0.unconfirmedTxs
            }
            .eraseToAnyPublisher()
    }
    
    private func addressData(walletAddress: String) -> AnyPublisher<BlockBookAddressResponse, Error> {
        provider
            .requestPublisher(target(for: .address(walletAddress: walletAddress)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockBookAddressResponse.self)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func unspentTxData(walletAddress: String) -> AnyPublisher<[BlockBookUnspentTxResponse], Error> {
        provider
            .requestPublisher(target(for: .txUnspents(walletAddress: walletAddress)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map([BlockBookUnspentTxResponse].self)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func target(for request: BlockBookTarget.Request) -> BlockBookTarget {
        BlockBookTarget(request: request, serviceProvider: serviceProvider, blockchain: blockchain, apiKey: apiKey)
    }
}
