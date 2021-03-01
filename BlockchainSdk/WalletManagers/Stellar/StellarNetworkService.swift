//
//  StellarNetworkService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import Combine

class StellarNetworkService {
    let stellarSdk: StellarSDK
    
    init(stellarSdk: StellarSDK) {
        self.stellarSdk = stellarSdk
    }
    
    @available(iOS 13.0, *)
    public func send(transaction: String) -> AnyPublisher<Bool, Error> {
        return stellarSdk.transactions.postTransaction(transactionEnvelope: transaction)
            .tryMap{ submitTransactionResponse throws  -> Bool in
                if submitTransactionResponse.transactionResult.code == .success {
                    return true
                } else {
                    throw "Result code: \(submitTransactionResponse.transactionResult.code)"
                }
        }
        .mapError { [unowned self] in self.mapError($0) }
        .eraseToAnyPublisher()
    }
    
    public func getInfo(accountId: String, isAsset: Bool) -> AnyPublisher<StellarResponse, Error> {
        return stellarData(accountId: accountId)
            .tryMap{ (accountResponse, ledgerResponse) throws -> StellarResponse in
                guard let baseFeeStroops = Decimal(ledgerResponse.baseFeeInStroops),
                    let baseReserveStroops = Decimal(ledgerResponse.baseReserveInStroops),
                    let balance = Decimal(accountResponse.balances.first(where: {$0.assetType == AssetTypeAsString.NATIVE})?.balance) else {
                        throw WalletError.failedToParseNetworkResponse
                }
                
                let sequence = accountResponse.sequenceNumber
                let assetBalances = try accountResponse.balances
                    .filter ({ $0.assetType != AssetTypeAsString.NATIVE })
                    .map { assetBalance -> StellarAssetResponse in
                        guard let code = assetBalance.assetCode,
                            let issuer = assetBalance.assetIssuer,
                            let balance = Decimal(assetBalance.balance) else {
                                throw WalletError.failedToParseNetworkResponse
                        }
                        
                        return StellarAssetResponse(code: code, issuer: issuer, balance: balance)
                }

                let divider =  Blockchain.stellar(testnet: false).decimalValue
                let baseFee = baseFeeStroops/divider
                let baseReserve = baseReserveStroops/divider
                
                return StellarResponse(baseFee: baseFee,
                                       baseReserve: baseReserve,
                                       assetBalances: assetBalances,
                                       balance: balance,
                                       sequence: sequence)
        }
        .mapError { [unowned self] in self.mapError($0, isAsset: isAsset) }
        .eraseToAnyPublisher()
    }
    
    private func stellarData(accountId: String) -> AnyPublisher<(AccountResponse, LedgerResponse), Error> {
        Publishers.Zip(stellarSdk.accounts.getAccountDetails(accountId: accountId),
                       stellarSdk.ledgers.getLatestLedger())
            .eraseToAnyPublisher()
    }
    
    private func mapError(_ error: Error, isAsset: Bool? = nil) -> Error {
        if let horizonError = error as? HorizonRequestError {
            if case .notFound = horizonError, let isAsset = isAsset {
                return WalletError.noAccount(message: isAsset ? "no_account_xlm_asset".localized : "no_account_xlm".localized)
            } else {
                return horizonError.parseError()
            }
        } else {
            return error
        }
    }
}

extension StellarNetworkService {
	public func getSignatureCount(accountId: String) -> AnyPublisher<Int, Error> {
		stellarSdk.operations.getAllOperations(accountId: accountId, recordsLimit: 1)
			.map { items in
				items.filter { $0.sourceAccount == accountId }.count
			}
			.mapError { [unowned self] in self.mapError($0) }
			.eraseToAnyPublisher()
	}
}


struct StellarResponse {
    let baseFee: Decimal
    let baseReserve: Decimal
    let assetBalances: [StellarAssetResponse]
    let balance: Decimal
    let sequence: Int64
}

struct StellarAssetResponse {
    let code: String
    let issuer: String
    let balance: Decimal
}

struct StellarTargetAccountResponse {
    let accountCreated: Bool
    let trustlineCreated: Bool
}
