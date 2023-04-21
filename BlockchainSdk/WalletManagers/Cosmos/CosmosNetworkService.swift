//
//  CosmosNetworkService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 10.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CosmosNetworkService: MultiNetworkProvider {
    let providers: [CosmosRestProvider]
    var currentProviderIndex: Int = 0
    
    private let cosmosChain: CosmosChain
    
    init(cosmosChain: CosmosChain, providers: [CosmosRestProvider]) {
        self.providers = providers
        self.cosmosChain = cosmosChain
    }
    
    func accountInfo(for address: String) -> AnyPublisher<CosmosAccountInfo, Error> {
        providerPublisher {
            $0.accounts(address: address)
                .zip($0.balances(address: address))
                .tryMap { [weak self] (accountInfo, balanceInfo) in
                    guard
                        let self,
                        let sequenceNumber = UInt64(accountInfo?.account.sequence ?? "0")
                    else {
                        throw WalletError.failedToParseNetworkResponse
                    }
                    
                    let accountNumber: UInt64?
                    if let account = accountInfo?.account {
                        accountNumber = UInt64(account.accountNumber)
                    } else {
                        accountNumber = nil
                    }
                    
                    let amount = try self.parseBalance(balanceInfo)
                    return CosmosAccountInfo(accountNumber: accountNumber, sequenceNumber: sequenceNumber, amount: amount)
                }
                .eraseToAnyPublisher()
        }
    }
    
    func estimateGas(for transaction: Data) -> AnyPublisher<UInt64, Error> {
        providerPublisher {
            $0.simulate(data: transaction)
                .map(\.gasInfo.gasUsed)
                .tryMap {
                    guard let gasUsed = UInt64($0) else {
                        throw WalletError.failedToGetFee
                    }
                    
                    return gasUsed
                }
                .eraseToAnyPublisher()
        }
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        providerPublisher {
            $0.txs(data: transaction)
                .map(\.txResponse)
                .tryMap { txResponse in
                    guard
                        let height = UInt64(txResponse.height),
                        height > 0
                    else {
                        throw WalletError.failedToSendTx
                    }
                    
                    return txResponse.txhash
                }
                .eraseToAnyPublisher()
        }
    }
    
    private func parseBalance(_ balanceInfo: CosmosBalanceResponse) throws -> Amount {
        guard let balanceAmountString = balanceInfo.balances.first(where: { $0.denom == cosmosChain.smallestDenomination } )?.amount else {
            return .zeroCoin(for: cosmosChain.blockchain)
        }
        
        guard let balanceInSmallestDenomination = Int(balanceAmountString) else {
            throw WalletError.failedToParseNetworkResponse
        }
        
        let blockchain = cosmosChain.blockchain
        return Amount(with: blockchain, value: Decimal(balanceInSmallestDenomination) / cosmosChain.blockchain.decimalValue)
    }
}
