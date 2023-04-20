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
    
    func accountInfo(for address: String, tokens: [Token]) -> AnyPublisher<CosmosAccountInfo, Error> {
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
                    
                    let rawAmount = try self.parseBalance(
                        balanceInfo,
                        denomination: cosmosChain.smallestDenomination,
                        decimalValue: cosmosChain.blockchain.decimalValue
                    )
                    let amount = Amount(with: self.cosmosChain.blockchain, value: rawAmount)
                    
                    let tokenAmounts: [Token: Decimal] = Dictionary(try tokens.compactMap {
                        guard let denomination = self.cosmosChain.tokenDenominationByContractAddress[$0.contractAddress] else {
                            return nil
                        }
                        
                        let balance = try self.parseBalance(balanceInfo, denomination: denomination, decimalValue: $0.decimalValue)
                        return ($0, balance)
                    }, uniquingKeysWith: {
                        pair1, _ in
                        pair1
                    })
                    
                    return CosmosAccountInfo(accountNumber: accountNumber, sequenceNumber: sequenceNumber, amount: amount, tokenBalances: tokenAmounts)
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
    
    private func parseBalance(_ balanceInfo: CosmosBalanceResponse, denomination: String, decimalValue: Decimal) throws -> Decimal {
        guard let balanceAmountString = balanceInfo.balances.first(where: { $0.denom == denomination } )?.amount else {
            return .zero
        }

        guard let balanceInSmallestDenomination = Int(balanceAmountString) else {
            throw WalletError.failedToParseNetworkResponse
        }
        
        return Decimal(balanceInSmallestDenomination) / decimalValue
    }
}
