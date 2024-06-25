//
//  ICPNetworkService.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class ICPNetworkService: MultiNetworkProvider {
    
    // MARK: - Protperties
    
    let providers: [ICPProvider]
    var currentProviderIndex: Int = 0
    
    private var blockchain: Blockchain
    
    // MARK: - Init
    
    init(providers: [ICPProvider], blockchain: Blockchain) {
        self.providers = providers
        self.blockchain = blockchain
    }
    
    
    func getInfo(address: String) -> AnyPublisher<Decimal, Error> {
        let address = "178197f9833164374be1e0ff8e9cf8b78c964f3ea294ab0da9bddc800c7ac64f"
        let method = accountBalanceMethod(address)
        
        return providerPublisher { provider in
            provider
                .getInfo(request: .query(method))
                .tryMap { [weak self] candidValue in
                    try self?.parseAccountBalanceResponse(candidValue) ?? 0
                }
                .eraseToAnyPublisher()
        }
    }
    
    private func accountBalanceMethod(_ address: String) -> ICPMethod {
        ICPMethod(
            canister: ICPSystemCanisters.ledger,
            methodName: "account_balance",
            args: .record([
                "account": .blob(Data(hex: address))
            ])
        )
    }
    
    private func parseAccountBalanceResponse(_ response: CandidValue) throws -> Decimal {
        guard let balance = response.ICPAmount else {
            throw ICPLedgerCanisterError.invalidResponse
        }
        return Decimal(balance) / blockchain.decimalValue
    }
}

public enum ICPLedgerCanisterError: Error {
    case invalidAddress
    case invalidResponse
    case transferFailed
}
