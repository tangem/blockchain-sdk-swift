//
//  StellarWalletmanager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 11.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import stellarsdk
import SwiftyJSON
import Combine
import TangemSdk

public enum StellarError: Int, Error, LocalizedError {
    // WARNING: Make sure to preserve the error codes when removing or inserting errors
    
    case emptyResponse
    case requiresMemo
    case failedToFindLatestLedger
    case xlmCreateAccount
    case assetCreateAccount
    case assetNoAccountOnDestination
    case assetNoTrustline
    
    // WARNING: Make sure to preserve the error codes when removing or inserting errors
    
    public var errorDescription: String? {
        switch self {
        case .requiresMemo:
            return "xlm_requires_memo_error".localized
        case .xlmCreateAccount:
            return "no_account_generic".localized(["1", "XLM"])
        case .assetCreateAccount:
            return "no_account_generic".localized(["1.5", "XLM"])
        case .assetNoAccountOnDestination:
            return "send_error_no_target_account".localized(["1 XLM"])
        case .assetNoTrustline:
            return "no_trustline_xlm_asset".localized
        default:
            return "generic_error_code".localized(errorCodeDescription)
        }
    }
    
    private var errorCodeDescription: String {
        "stellar_error \(rawValue)"
    }
}

class StellarWalletManager: BaseManager, WalletManager {
    var txBuilder: StellarTransactionBuilder!
    var networkService: StellarNetworkService!
    var currentHost: String { networkService.host  }
    
    override func update(completion: @escaping (Result<(), Error>)-> Void)  {
        cancellable = networkService
            .getInfo(accountId: wallet.address, isAsset: !cardTokens.isEmpty)
            .sink(receiveCompletion: {[unowned self] completionSubscription in
                if case let .failure(error) = completionSubscription {
                    self.wallet.amounts = [:]
                    completion(.failure(error))
                }
            }, receiveValue: { [unowned self] response in
                self.updateWallet(with: response)
                completion(.success(()))
            })
    }
    
    private func updateWallet(with response: StellarResponse) {
        txBuilder.sequence = response.sequence
        let fullReserve = response.assetBalances.isEmpty ? response.baseReserve * 2 : response.baseReserve * 3
        wallet.add(reserveValue: fullReserve)
        wallet.add(coinValue: response.balance - fullReserve)
        
        if cardTokens.isEmpty {
            response.assetBalances.forEach {
                let token = Token(name: $0.code,
                                  symbol: $0.code,
                                  contractAddress: $0.issuer,
                                  decimalCount: wallet.blockchain.decimalCount)
                wallet.add(tokenValue: $0.balance, for: token)
            }
        } else {
            for token in cardTokens {
                let assetBalance = response.assetBalances.first(where: { $0.code == token.symbol })?.balance ?? 0.0
                wallet.add(tokenValue: assetBalance, for: token)
                
            }
        }

        // We believe that a transaction will be confirmed within 10 seconds
        let date = Date(timeIntervalSinceNow: -10)
        wallet.removePendingTransaction(older: date)
    }
}

extension StellarWalletManager: TransactionSender {
    var allowsFeeSelection: Bool { true }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, Error> {
        return networkService.checkTargetAccount(transaction: transaction)
            .flatMap { [weak self] response -> AnyPublisher<(hash: Data, transaction: stellarsdk.TransactionXDR), Error> in
                guard let self else { return .emptyFail }
                
                return self.txBuilder.buildForSign(targetAccountResponse: response, transaction: transaction)
            }
            .flatMap {[weak self] buildForSignResponse -> AnyPublisher<(Data, (hash: Data, transaction: stellarsdk.TransactionXDR)), Error> in
                guard let self = self else { return .emptyFail }
                
                return signer.sign(hash: buildForSignResponse.hash,
                                   walletPublicKey: self.wallet.publicKey)
                    .map { return ($0, buildForSignResponse) }.eraseToAnyPublisher()
            }
            .tryMap {[weak self] result throws -> String in
                guard let self = self else { throw WalletError.empty }
                
                guard let tx = self.txBuilder.buildForSend(signature: result.0, transaction: result.1.transaction) else {
                    throw WalletError.failedToBuildTx
                }
                
                return tx
            }
            .flatMap {[weak self] hash -> AnyPublisher<TransactionSendResult, Error> in
                self?.networkService.send(transaction: hash).tryMap {[weak self] sendResponse in
                    guard let self = self else { throw WalletError.empty }
                    
                    let mapper = PendingTransactionRecordMapper()
                    let record = mapper.mapToPendingTransactionRecord(transaction: transaction, hash: hash)
                    self.wallet.addPendingTransaction(record)
                    return TransactionSendResult(hash: hash)
                }
                .mapError { SendTxError(error: $0, tx: hash) }
                .eraseToAnyPublisher() ?? .emptyFail
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        networkService.getFee()
            .map { $0.map { Fee($0) } }
            .eraseToAnyPublisher()
    }
}

extension StellarWalletManager: SignatureCountValidator {
    func validateSignatureCount(signedHashes: Int) -> AnyPublisher<Void, Error> {
        networkService.getSignatureCount(accountId: wallet.address)
            .tryMap {
                if signedHashes != $0 { throw BlockchainSdkError.signatureCountNotMatched }
            }
            .eraseToAnyPublisher()
    }
}

extension StellarWalletManager: ThenProcessable { }
