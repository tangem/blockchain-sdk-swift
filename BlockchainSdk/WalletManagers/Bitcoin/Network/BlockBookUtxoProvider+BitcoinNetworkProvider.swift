//
//  BlockBookUtxoProvider+Netw.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 26.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

// TODO: - Will be refactored for support managing utxos

// MARK: - BitcoinNetworkProvider

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
                    balance: (Decimal(string: addressResponse.balance) ?? 0) / self.decimalValue,
                    hasUnconfirmed: addressResponse.unconfirmedTxs != 0,
                    pendingTxRefs: self.pendingTransactions(from: transactions, address: address),
                    unspentOutputs: self.unspentOutputs(from: unspentTxResponse, transactions: transactions, address: address)
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        // Number of blocks we want the transaction to be confirmed in.
        // The lower the number the bigger the fee returned by 'estimatesmartfee'.
        let confirmationBlocks = [8, 4, 1]
        
        return Publishers.MergeMany(confirmationBlocks.map {
            getFeeRatePerByte(for: $0)
        })
        .collect()
        .map { $0.sorted() }
        .tryMap { fees -> BitcoinFee in
            guard fees.count == confirmationBlocks.count else {
                throw BlockchainSdkError.failedToLoadFee
            }
            
            return BitcoinFee(
                minimalSatoshiPerByte: fees[0],
                normalSatoshiPerByte: fees[1],
                prioritySatoshiPerByte: fees[2]
            )
        }
        .eraseToAnyPublisher()
    }
    
    func send(transaction: String) -> AnyPublisher<String, Error> {
        return sendTransaction(hex: transaction)
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

// MARK: - Mapping

private extension BlockBookUtxoProvider {
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
                        let outputIndex = input.vout,
                        let txid = input.txid
                    else {
                        return nil
                    }
                    
                    return BitcoinInput(
                        sequence: input.n,
                        address: address,
                        outputIndex: outputIndex,
                        outputValue: value,
                        prevHash: txid
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
                                          value: pendingTransactionInfo.value / self.decimalValue,
                                          source: pendingTransactionInfo.source,
                                          fee: fetchedFees / self.decimalValue,
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
            .compactMap { vout in
                vout.hex
            }
            .first
        
        guard let outputScript = outputScript else {
            return []
        }
        
        return utxos.compactMap { utxo in
            guard let value = UInt64(utxo.value), utxo.confirmations > 0 else {
                return nil
            }
            
            return BitcoinUnspentOutput(
                transactionHash: utxo.txid,
                outputIndex: utxo.vout,
                amount: value,
                outputScript: outputScript
            )
        }
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
