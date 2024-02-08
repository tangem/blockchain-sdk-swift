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
        providerPublisher { [weak self] provider in
            guard let self else { return .emptyFail }
            return provider
                .getFeeEstimate(body: .init(cost: cost, targetTimes: [60, 300]))
                .map { response in
                    let lowEstimatedFee = Double(cost) * response.feeRateLastBlock * MultiplicatorConstants.lowMultiplicatorFeeRate
                    let mediumEstimatedFee = Double(cost) * response.feeRateLastBlock * MultiplicatorConstants.mediumMultiplicatorFeeRate
                    let highEstimatedFee = Double(cost) * response.feeRateLastBlock * MultiplicatorConstants.highMultiplicatorFeeRate
                    
                    let feeValues = [
                        lowEstimatedFee,
                        mediumEstimatedFee,
                        highEstimatedFee
                    ]
                    
                    let estimatedFeeValues = feeValues.map {
                        let decimalValue = Decimal($0) / self.blockchain.decimalValue
                        let amountValue = Amount(with: self.blockchain, value: decimalValue)
                        return Fee(amountValue)
                    }
                    
                    return estimatedFeeValues
                }
                .eraseToAnyPublisher()
        }
    }
}

extension ChiaNetworkService {
    /// Necessary to increase the value of the commission due to the fact that receiving a commission via API does not always work correctly
    enum MultiplicatorConstants {
        static let lowMultiplicatorFeeRate: Double = 1.5
        static let mediumMultiplicatorFeeRate: Double = 2
        static let highMultiplicatorFeeRate: Double = 5
    }
}
