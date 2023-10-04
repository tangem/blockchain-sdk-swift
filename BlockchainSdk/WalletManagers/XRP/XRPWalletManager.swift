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

public enum XRPError: Int, Error, LocalizedError {
    // WARNING: Make sure to preserve the error codes when removing or inserting errors
    
    case failedLoadUnconfirmed
    case failedLoadReserve
    case failedLoadInfo
    case missingReserve
    case distinctTagsFound
    
    // WARNING: Make sure to preserve the error codes when removing or inserting errors
    
    public var errorDescription: String? {
        "generic_error_code".localized("xrp_error \(rawValue)")
    }
}

class XRPWalletManager: BaseManager, WalletManager {
    var txBuilder: XRPTransactionBuilder!
    var networkService: XRPNetworkService!
    
    var currentHost: String { networkService.host }
    
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
        if response.balance != response.unconfirmedBalance, wallet.pendingTransactions.isEmpty {
            wallet.addDummyPendingTransaction()
        } else {
            wallet.clearPendingTransaction()
        }
    }
}

extension XRPWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        let addressDecoded = (try? XRPAddress.decodeXAddress(xAddress: transaction.destinationAddress))?.rAddress ?? transaction.destinationAddress
        return networkService
            .checkAccountCreated(account: addressDecoded)
            .tryMap{[weak self] isAccountCreated -> (XRPTransaction, Data) in
                guard let self = self else { throw WalletError.empty }
                
                guard let walletReserve = self.wallet.amounts[.reserve],
                      let buldResponse = try self.txBuilder.buildForSign(transaction: transaction) else {
                          throw XRPError.missingReserve
                      }
                
                if !isAccountCreated && transaction.amount.value < walletReserve.value {
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
            .flatMap{[weak self] builderResponse -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(blob: builderResponse)
                    .tryMap{[weak self] response in
                        guard let self = self else { throw WalletError.empty }
                        
                        let hash = builderResponse
                        self.wallet.addPendingTransaction(transaction.asPending(hash: hash))
                        return TransactionSendResult(hash: hash)
                    }
                    .mapError { SendTxError(error: $0, tx: builderResponse) }
                    .eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        return networkService.getFee()
            .map { [weak self] xrpFeeResponse -> [Fee] in
                guard let self else { return [] }
                let blockchain = self.wallet.blockchain
                
                let min = xrpFeeResponse.min / blockchain.decimalValue
                let normal = xrpFeeResponse.normal / blockchain.decimalValue
                let max = xrpFeeResponse.max / blockchain.decimalValue
                
                let minFee = Amount(with: blockchain, value: min)
                let normalFee = Amount(with: blockchain, value: normal)
                let maxFee = Amount(with: blockchain, value: max)

                return [minFee, normalFee, maxFee].map { Fee($0) }
            }
            .eraseToAnyPublisher()
    }
}

extension XRPWalletManager: ThenProcessable { }
