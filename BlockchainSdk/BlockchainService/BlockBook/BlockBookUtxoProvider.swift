//
//  BlockBookUtxoProvider.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BlockBookUtxoProvider {
    var host: String {
        config.host
    }
    
    private let blockchain: Blockchain
    private let config: BlockBookConfig
    private let provider: NetworkProvider<BlockBookTarget>
    
    init(blockchain: Blockchain, blockBookConfig: BlockBookConfig, networkConfiguration: NetworkProviderConfiguration) {
        self.blockchain = blockchain
        self.config = blockBookConfig
        self.provider = NetworkProvider<BlockBookTarget>(configuration: networkConfiguration)
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
        BlockBookTarget(request: request, config: config, blockchain: blockchain)
    }
    
    private func pendingTransactions(from transactions: [BlockBookAddressResponse.Transaction], address: String) -> [PendingTransaction] {
        transactions
            .filter {
                $0.confirmations == 0
            }
            .compactMap { tx -> PendingTransaction? in
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
                    let pendingTransactionInfo = pendingTransactionInfo(from: tx, address: address),
                    let fetchedFees = Decimal(string: tx.fees)
                else {
                    return nil
                }

                return PendingTransaction(hash: tx.txid,
                                          destination: pendingTransactionInfo.destination,
                                          value: pendingTransactionInfo.value / self.blockchain.decimalValue,
                                          source: pendingTransactionInfo.source,
                                          fee: fetchedFees / self.blockchain.decimalValue,
                                          date: Date(timeIntervalSince1970: Double(tx.blockTime)),
                                          isIncoming: pendingTransactionInfo.isIncoming,
                                          transactionParams: BitcoinTransactionParams(inputs: bitcoinInputs))
            }
    }
    
    private func pendingTransactionInfo(from tx: BlockBookAddressResponse.Transaction, address: String) -> PendingTransactionInfo? {
        if tx.vin.contains(where: { $0.addresses.contains(address) }), let destinationUtxo = tx.vout.first(where: { !$0.addresses.contains(address) }) {
            guard let destination = destinationUtxo.addresses.first,
                  let value = Decimal(string: destinationUtxo.value)
            else {
                return nil
            }
            
            return PendingTransactionInfo(
                isIncoming: false,
                source: address,
                destination: destination,
                value: value
            )
        } else if let txDestination = tx.vout.first(where: { $0.addresses.contains(address) }), !tx.vin.contains(where: { $0.addresses.contains(address) }), let txSource = tx.vin.first {
            guard
                let source = txSource.addresses.first,
                let value = Decimal(string: txDestination.value)
            else {
                return nil
            }
            
            return PendingTransactionInfo(
                isIncoming: true,
                source: source,
                destination: address,
                value: value
            )
        } else {
            return nil
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

extension BlockBookUtxoProvider: BitcoinNetworkProvider {
    var supportsTransactionPush: Bool { false }
    
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
                
                if $0.result.feerate <= 0 {
                    throw BlockchainSdkError.failedToLoadFee
                }
                
                let feeRate = Decimal($0.result.feerate) * self.blockchain.decimalValue
                
                let min = (Decimal(0.8) * feeRate).rounded(roundingMode: .up)
                let normal = feeRate.rounded(roundingMode: .up)
                let max = (Decimal(1.2) * feeRate).rounded(roundingMode: .up)
                
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
}

fileprivate extension BlockBookUtxoProvider {
    struct PendingTransactionInfo {
        let isIncoming: Bool
        let source: String
        let destination: String
        let value: Decimal
    }
}
