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
                        let accountNumber = UInt64(accountInfo.account.accountNumber),
                        let sequenceNumber = UInt64(accountInfo.account.sequence),
                        let balanceInfo = balanceInfo.balances.first(where: { $0.denom == self.cosmosChain.smallestDenomination } ),
                        let balanceInSmallestDenomination = Int(balanceInfo.amount)
                    else {
                        throw WalletError.failedToGetFee
                    }
                    
                    let blockchain = self.cosmosChain.blockchain
                    let amount = Amount(with: blockchain, value: Decimal(balanceInSmallestDenomination) / blockchain.decimalValue)
                    
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
                .map(\.txResponse.txhash)
                .eraseToAnyPublisher()
        }
    }
}
