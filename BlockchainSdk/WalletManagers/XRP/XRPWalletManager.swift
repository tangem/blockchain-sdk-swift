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

class XRPWalletManager: BaseManager, WalletManager {
    var txBuilder: XRPTransactionBuilder!
    var networkService: XRPNetworkService!
    
    var currentHost: String { networkService.host }
    
    func update(completion: @escaping (Result<Void, Error>)-> Void) {
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

extension XRPWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        let addressDecoded = (try? XRPAddress.decodeXAddress(xAddress: transaction.destinationAddress))?.rAddress ?? transaction.destinationAddress
        return networkService
            .checkAccountCreated(account: addressDecoded)
            .tryMap{[weak self] isAccountCreated -> (XRPTransaction, Data) in
                guard let self = self else { throw WalletError.empty }
                
                guard let walletReserve = self.wallet.amounts[.reserve]?.value,
                      let buldResponse = try self.txBuilder.buildForSign(transaction: transaction) else {
                          throw XRPError.missingReserve
                      }
                
                if !isAccountCreated && transaction.amount.value < walletReserve {
                    throw String(format: "send_error_no_target_account".localized, walletReserve.description)
                }
                
                return buldResponse
            }
            .flatMap{[weak self] buildResponse -> AnyPublisher<(XRPTransaction, Data),Error> in
                guard let self = self else { return .emptyFail }
                
                return signer.sign(hash: buildResponse.1,
                                   walletPublicKey: self.wallet.publicKey).map {
                    return (buildResponse.0, $0)
                }.eraseToAnyPublisher()
            }
            .tryMap{[weak self] response -> (String) in
                guard let self = self else { throw WalletError.empty }

                return try self.txBuilder.buildForSend(transaction: response.0, signature: response.1)
            }
            .flatMap{[weak self] builderResponse -> AnyPublisher<Void, Error> in
                self?.networkService.send(blob: builderResponse)
                    .tryMap{[weak self] response in
                        guard let self = self else { throw WalletError.empty }
                        
                        return self.wallet.add(transaction: transaction)
                    }
                    .mapError { SendTxError(error: $0, tx: builderResponse) }
                    .eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        return networkService.getFee()
            .map { xrpFeeResponse -> [Amount] in
                let min = xrpFeeResponse.min/Decimal(1000000)
                let normal = xrpFeeResponse.normal/Decimal(1000000)
                let max = xrpFeeResponse.max/Decimal(1000000)
                
                let minAmount = Amount(with: self.wallet.blockchain, value: min)
                let normalAmount = Amount(with: self.wallet.blockchain, value: normal)
                let maxAmount = Amount(with: self.wallet.blockchain, value: max)
                return [minAmount, normalAmount, maxAmount]
            }
            .eraseToAnyPublisher()
    }
}

extension XRPWalletManager: ThenProcessable { }
