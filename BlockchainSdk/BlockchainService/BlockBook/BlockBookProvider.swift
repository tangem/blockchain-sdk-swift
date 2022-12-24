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
    private let provider: NetworkProvider<BlockBookTarget>
    
    init(blockchain: Blockchain, serviceProvider: BlockBookService, configuration: NetworkProviderConfiguration) {
        self.blockchain = blockchain
        self.serviceProvider = serviceProvider
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
                    .filter {
                        $0.confirmations > 0
                    }
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
                
                let pendingRefs: [PendingTransaction] = transactions
                    .filter({ $0.confirmations == 0 })
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
                            
                            return BitcoinInput(sequence: input.n, address: address, outputIndex: outputIndex, outputValue: value, prevHash: input.txid)
                        }
                        
                        let fee: Decimal?
                        if let fetchedFees = Decimal(string: tx.fees) {
                            fee = fetchedFees / self.blockchain.decimalValue
                        } else {
                            fee = nil
                        }
                        
                        guard
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
                                                  fee: fee,
                                                  date: date,
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
        BlockBookTarget(request: request, serviceProvider: serviceProvider, blockchain: blockchain)
    }
}
