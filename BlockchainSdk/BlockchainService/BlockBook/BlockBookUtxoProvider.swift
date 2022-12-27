//
//  BlockBookUtxoProvider.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BlockBookUtxoProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    
    var host: String {
        serviceProvider.host
    }
    
    private let blockchain: Blockchain
    private let serviceProvider: BlockBookService
    private let provider: NetworkProvider<BlockBookTarget>
    
    init(blockchain: Blockchain, serviceProvider: BlockBookService, configuration: NetworkProviderConfiguration) {
        self.blockchain = blockchain
        self.serviceProvider = serviceProvider
        self.provider = NetworkProvider<BlockBookTarget>(configuration: configuration)
    }
    
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        Publishers
            .Zip(addressData(address: address), unspentTxData(address: address))
            .tryMap { [weak self] (addressResponse, unspentTxResponse) in
                guard let self else {
                    throw WalletError.empty
                }
                
                let transactions = addressResponse.transactions ?? []
                
                return BitcoinResponse(
                    balance: (Decimal(string: addressResponse.balance) ?? 0) / self.blockchain.decimalValue,
                    hasUnconfirmed: addressResponse.unconfirmedTxs != 0,
                    pendingTxRefs: self.pendingTransactions(from: transactions, address: address),
                    unspentOutputs: self.unspentOutputs(from: unspentTxResponse, transactions: transactions, address: address)
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        provider
            .requestPublisher(target(for: .fees))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockBookFeeResponse.self)
            .tryMap { [weak self] in
                guard let self else {
                    throw WalletError.empty
                }
                
                let feeRate = Decimal($0.result.feerate) * self.blockchain.decimalValue
                
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
        .anyFail(error: "RBF not supported")
    }
    
    func getSignatureCount(address: String) -> AnyPublisher<Int, Error> {
        addressData(address: address)
            .tryMap {
                $0.txs + $0.unconfirmedTxs
            }
            .eraseToAnyPublisher()
    }
    
    private func addressData(address: String) -> AnyPublisher<BlockBookAddressResponse, Error> {
        provider
            .requestPublisher(target(for: .address(address: address)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map(BlockBookAddressResponse.self)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func unspentTxData(address: String) -> AnyPublisher<[BlockBookUnspentTxResponse], Error> {
        provider
            .requestPublisher(target(for: .utxo(address: address)))
            .filterSuccessfulStatusAndRedirectCodes()
            .map([BlockBookUnspentTxResponse].self)
            .eraseError()
            .eraseToAnyPublisher()
    }
    
    private func target(for request: BlockBookTarget.Request) -> BlockBookTarget {
        BlockBookTarget(request: request, serviceProvider: serviceProvider, blockchain: blockchain)
    }
    
    private func pendingTransactions(from transactions: [BlockBookAddressResponse.Transaction], address: String) -> [PendingTransaction] {
        transactions
            .filter {
                $0.confirmations == 0
            }
            .compactMap { tx -> PendingTransaction? in
                let source: String?
                let destination: String?
                let value: Decimal?
                let isIncoming: Bool
                
                if tx.vin.contains(where: { $0.addresses.contains(address) }), let destinationUtxo = tx.vout.first(where: { !$0.addresses.contains(address) }) {
                    isIncoming = false
                    destination = destinationUtxo.addresses.first
                    source = address
                    value = Decimal(string: destinationUtxo.value)
                } else if let txDestination = tx.vout.first(where: { $0.addresses.contains(address) }), !tx.vin.contains(where: { $0.addresses.contains(address) }), let txSource = tx.vin.first {
                    isIncoming = true
                    destination = address
                    source = txSource.addresses.first
                    value = Decimal(string: txDestination.value)
                } else {
                    return nil
                }
                
                let bitcoinInputs: [BitcoinInput] = tx.vin.compactMap { input -> BitcoinInput? in
                    guard
                        let address = input.addresses.first,
                        let value = UInt64(input.value ?? ""),
                        let outputIndex = input.vout
                    else {
                        return nil
                    }
                    
                    return BitcoinInput(
                        sequence: input.n,
                        address: address,
                        outputIndex: outputIndex,
                        outputValue: value,
                        prevHash: input.txid
                    )
                }
                
                guard
                    let fetchedFees = Decimal(string: tx.fees),
                    let source,
                    let destination,
                    let value
                else {
                    return nil
                }
                
                let date = Date(timeIntervalSince1970: Double(tx.blockTime))
                
                return PendingTransaction(hash: tx.txid,
                                          destination: destination,
                                          value: value / self.blockchain.decimalValue,
                                          source: source,
                                          fee: fetchedFees / self.blockchain.decimalValue,
                                          date: date,
                                          isIncoming: isIncoming,
                                          transactionParams: BitcoinTransactionParams(inputs: bitcoinInputs))
            }
    }
    
    private func unspentOutputs(from utxos: [BlockBookUnspentTxResponse], transactions: [BlockBookAddressResponse.Transaction], address: String) -> [BitcoinUnspentOutput] {
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
        
        guard let outputScript = outputScript else {
            return []
        }
        
        return utxos.compactMap {
            guard let value = UInt64($0.value) else { return nil}
            
            return BitcoinUnspentOutput(
                transactionHash: $0.txid,
                outputIndex: $0.vout,
                amount: value,
                outputScript: outputScript
            )
        }
    }
}
