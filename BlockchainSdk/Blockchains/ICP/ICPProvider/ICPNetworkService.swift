//
//  ICPNetworkService.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import PotentCBOR

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
    
    func send(data: Data) -> AnyPublisher<Void, Error> {
        providerPublisher { provider in
            provider
                .send(data: data)
        }
    }
    
    func readState(data: Data, paths: [ICPStateTreePath]) -> AnyPublisher<UInt64?, Error> {
        providerPublisher { provider in
            provider
                .readState(data: data, paths: paths)
                .map { [weak self] result in
                    try? result.flatMap { try self?.parseTranserResponse($0) }
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
    
    private func parseTranserResponse(_ response: CandidValue) throws -> UInt64 {
        guard let variant = response.variantValue else {
            throw ICPLedgerCanisterError.invalidResponse
        }
        
        guard let blockIndex = variant["Ok"]?.natural64Value else {
            guard let error = variant["Err"]?.variantValue else {
                throw ICPLedgerCanisterError.invalidResponse
            }
            if let badFee = error["BadFee"]?.recordValue,
               let expectedFee = badFee["expected_fee"]?.ICPAmount {
                throw ICPTransferError.badFee(expectedFee: expectedFee)
                
            } else if let insufficientFunds = error["InsufficientFunds"]?.recordValue,
                      let balance = insufficientFunds["balance"]?.ICPAmount {
                
                throw ICPTransferError.insufficientFunds(balance: balance)
                                                      
            } else if let txTooOld = error["TxTooOld"]?.recordValue,
                      let allowed = txTooOld["allowed_window_nanos"]?.natural64Value {
                throw ICPTransferError.transactionTooOld(allowedWindowNanoSeconds: allowed)
                
            } else if let _ = error["TxCreatedInFuture"] {
                throw ICPTransferError.transactionCreatedInFuture
                
            } else if let txDuplicate = error["TxDuplicate"]?.recordValue,
                      let blockIndex = txDuplicate["duplicate_of"]?.natural64Value {
                throw ICPTransferError.transactionDuplicate(blockIndex: blockIndex)
            }
            throw ICPLedgerCanisterError.invalidResponse
        }
        return blockIndex
    }
}

public enum ICPTransferError: Error {
    case badFee(expectedFee: UInt64)
    case insufficientFunds(balance: UInt64)
    case transactionTooOld(allowedWindowNanoSeconds: UInt64)
    case transactionCreatedInFuture
    case transactionDuplicate(blockIndex: UInt64)
    case couldNotFindPostedTransaction
}

public enum ICPLedgerCanisterError: Error {
    case invalidAddress
    case invalidResponse
    case transferFailed
}
