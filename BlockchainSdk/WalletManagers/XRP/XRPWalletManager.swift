//
//  XRPWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 10.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

public enum XRPError: String, Error, LocalizedError {
    case failedLoadUnconfirmed = "xrp_load_unconfirmed_error"
    case failedLoadReserve = "xrp_load_reserve_error"
    case failedLoadInfo = "xrp_load_account_error"
    case missingReserve = "xrp_missing_reserve_error"
    case distinctTagsFound
    
    public var errorDescription: String? {
        switch self {
        case .distinctTagsFound:
            return rawValue
        default:
            return rawValue.localized
        }
    }
}

class XRPWalletManager: WalletManager {
    var txBuilder: XRPTransactionBuilder!
    var networkService: XRPNetworkService!
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(account: wallet.address)
            .sink(receiveCompletion: {[unowned self]  completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
                }, receiveValue: { [unowned self] response in
                    self.updateWallet(with: response)
                    completion(.success(()))
            })
    }
    
    private func updateWallet(with response: XrpInfoResponse) {
        wallet.add(reserveValue: response.reserve/Decimal(1000000))
        wallet.add(coinValue: (response.balance - response.reserve)/Decimal(1000000))
        
        txBuilder.account = wallet.address
        txBuilder.sequence = response.sequence
        if response.balance != response.unconfirmedBalance {
            if wallet.transactions.isEmpty {
                wallet.addDummyPendingTransaction()
            }
        } else {
            wallet.transactions = []
        }
    }
}

@available(iOS 13.0, *)
extension XRPWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<SignResponse, Error> {
        let addressDecoded = (try? XRPAddress.decodeXAddress(xAddress: transaction.destinationAddress))?.rAddress ?? transaction.destinationAddress
        return networkService
            .checkAccountCreated(account: addressDecoded)
            .tryMap{[unowned self] isAccountCreated -> (XRPTransaction, Data) in
                guard let walletReserve = self.wallet.amounts[.reserve]?.value,
                    let buldResponse = try self.txBuilder.buildForSign(transaction: transaction) else {
                        throw XRPError.missingReserve
                }
                
                if !isAccountCreated && transaction.amount.value < walletReserve {
                    throw String(format: "xrp_target_not_created_format".localized, walletReserve.description)
                }
                
                return buldResponse
        }
        .flatMap{[unowned self] buildResponse -> AnyPublisher<(XRPTransaction, SignResponse),Error> in
            return signer.sign(hashes: [buildResponse.1], cardId: self.cardId).map {
                return (buildResponse.0, $0)
            }.eraseToAnyPublisher()
        }
        .tryMap{[unowned self] response -> (String,SignResponse) in
            guard let tx = self.txBuilder.buildForSend(transaction: response.0, signature: response.1.signature) else {
                throw WalletError.failedToBuildTx
            }
            
            return (tx, response.1)
        }
        .flatMap{[unowned self] builderResponse -> AnyPublisher<SignResponse, Error> in
            self.networkService.send(blob: builderResponse.0)
                .map{[unowned self] response in
                    self.wallet.add(transaction: transaction)
                    return builderResponse.1
            }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String, includeFee: Bool) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .map { xrpFeeResponse -> [Amount] in
                let min = xrpFeeResponse.min/Decimal(1000000)
                let normal = xrpFeeResponse.normal/Decimal(1000000)
                let max = xrpFeeResponse.max/Decimal(1000000)
                
                let minAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: min)
                let normalAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: normal)
                let maxAmount = Amount(with: self.wallet.blockchain, address: self.wallet.address, value: max)
                return [minAmount, normalAmount, maxAmount]
        }
        .eraseToAnyPublisher()
    }
}

extension XRPWalletManager: ThenProcessable { }
