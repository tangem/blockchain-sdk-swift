//
//  ChiaNetworkService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 14.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class ChiaNetworkService: MultiNetworkProvider {
    // MARK: - Protperties
    
    let providers: [ChiaNetworkProvider]
    var currentProviderIndex: Int = 0
    
    private var blockchain: Blockchain
    
    // MARK: - Init
    
    init(providers: [ChiaNetworkProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
    
    // MARK: - Implementation
    
    func getUnspents(puzzleHash: String) -> AnyPublisher<[ChiaCoin], Error> {
        providerPublisher { provider in
            provider
                .getUnspents(puzzleHash: puzzleHash)
                .map { response in
                    return response.coinRecords.map { $0.coin }
                }
                .eraseToAnyPublisher()
        }
    }
    
    func send(spendBundle: ChiaSpendBundle) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider
                .sendTransaction(body: ChiaTransactionBody(spendBundle: spendBundle))
                .tryMap { response in
                    guard response.status == ChiaSendTransactionResponse.Constants.successStatus else {
                        throw WalletError.failedToSendTx
                    }
                    
                    return ""
                }
                .eraseToAnyPublisher()
        }
    }
    
    func getFee(with cost: Int64) -> AnyPublisher<[Fee], Error> {
        providerPublisher { [unowned self] provider in
            provider
                .getFeeEstimate(body: .init(cost: cost, targetTimes: [60, 300]))
                .map { response in
                    let countAllowFeeSelection = 3
                    
                    var estimatedFees: [Fee] = response.estimates.sorted().map { estimate in
                        let value = Decimal(estimate) / self.blockchain.decimalValue
                        let amount = Amount(with: self.blockchain, value: value)
                        return Fee(amount)
                    }
                    
                    guard estimatedFees.count < countAllowFeeSelection else {
                        return estimatedFees
                    }
                    
                    for _ in 0..<countAllowFeeSelection-response.estimates.count {
                        estimatedFees.insert(Fee(Amount(with: self.blockchain, value: Decimal(0))), at: 0)
                    }
                    
                    return estimatedFees
                }
                .eraseToAnyPublisher()
        }
    }
}
