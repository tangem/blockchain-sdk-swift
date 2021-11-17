//
//  TezosWalletManager.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 20.10.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import stellarsdk

class TezosWalletManager: WalletManager {
    var txBuilder: TezosTransactionBuilder!
    var networkService: TezosNetworkService!
    
    override var currentHost: String {
        networkService.host
    }
    
    override func update(completion: @escaping (Result<Void, Error>)-> Void) {
        cancellable = networkService
            .getInfo(address: wallet.address)
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
    
    private func updateWallet(with response: TezosAddress) {
        txBuilder.counter = response.counter
        
        if response.balance != wallet.amounts[.coin]?.value {
            wallet.transactions = []
        }
        
        wallet.add(coinValue: response.balance)
    }
}

extension TezosWalletManager: TransactionSender {
    var allowsFeeSelection: Bool {
        false
    }
    
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<Void, Error> {
        guard let contents = txBuilder.buildContents(transaction: transaction) else {
            return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
        }
        
        return networkService
            .getHeader()
            .tryMap {[weak self] header -> (TezosHeader, String) in
                guard let self = self else { throw WalletError.empty }
                
                let forged = try self.txBuilder
                    .forgeContents(headerHash: header.hash, contents: contents)
                
                return (header, forged)
            }
            .flatMap {[weak self] (header, forgedContents) -> AnyPublisher<(header: TezosHeader, forgedContents: String, signature: Data), Error> in
                guard let self = self else { return .emptyFail }
                
                guard let txToSign: Data = self.txBuilder.buildToSign(forgedContents: forgedContents) else {
                    return Fail(error: WalletError.failedToBuildTx).eraseToAnyPublisher()
                }
                
                return signer.sign(hash: txToSign, cardId: self.wallet.cardId, walletPublicKey: self.wallet.publicKey)
                    .map {signature -> (TezosHeader, String, Data) in
                        return (header, forgedContents, signature)
                    }
                    .eraseToAnyPublisher()
            }
            .flatMap {[weak self] (header, forgedContents, signature) -> AnyPublisher<(String, Data), Error> in
                guard let self = self else { return .emptyFail }
                
                return self.networkService
                    .checkTransaction(protocol: header.protocol, hash: header.hash, contents: contents, signature: self.encodeSignature(signature))
                    .map { _ in (forgedContents, signature) }
                    .eraseToAnyPublisher()
            }
            .flatMap {[weak self] (forgedContents, signature) -> AnyPublisher<Void, Error> in
                guard let self = self else { return .emptyFail }
                
                let txToSend = self.txBuilder.buildToSend(signature: signature, forgedContents: forgedContents)
                return self.networkService
                    .sendTransaction(txToSend)
                    .tryMap{[weak self] response in
                        guard let self = self else { throw WalletError.empty }
                        
                        self.wallet.add(transaction: transaction)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        networkService
            .checkPublicKeyRevealed(address: wallet.address)
            .combineLatest(networkService.getInfo(address: destination))
            .tryMap {[weak self] (isPublicKeyRevealed, destinationInfo) -> [Amount] in
                guard let self = self else { throw WalletError.empty }
                
                self.txBuilder.isPublicKeyRevealed = isPublicKeyRevealed
                var fee = TezosFee.transaction.rawValue
                if !isPublicKeyRevealed {
                    fee += TezosFee.reveal.rawValue
                }
                
                if destinationInfo.balance == 0 {
                    fee += TezosFee.allocation.rawValue
                }
                
                return [Amount(with: self.wallet.blockchain, value: fee)]
            }
            .eraseToAnyPublisher()
    }
    
    private func encodeSignature(_ signature: Data) -> String {
        let edsigPrefix = TezosPrefix.signaturePrefix(for: wallet.blockchain.curve)
        let prefixedSignature = edsigPrefix + signature
        let checksum = prefixedSignature.sha256().sha256().prefix(4)
        let prefixedSignatureWithChecksum = prefixedSignature + checksum
        return Base58.encode(prefixedSignatureWithChecksum)
    }
}


extension TezosWalletManager: ThenProcessable { }


extension TezosWalletManager: WithdrawalValidator {
    func validate(_ transaction: Transaction) -> WithdrawalWarning? {
        guard let walletAmount = wallet.amounts[.coin] else {
            return nil
        }
        
        let minimumAmount: Decimal = 0.000001
        
        if transaction.amount + transaction.fee == walletAmount {
            return WithdrawalWarning(warningMessage: String(format: "xtz_withdrawal_message_warning".localized, minimumAmount.description),
                                     reduceMessage: String(format: "xtz_withdrawal_message_reduce".localized, minimumAmount.description),
                                     ignoreMessage: "xtz_withdrawal_message_ignore".localized,
                                     suggestedReduceAmount: Amount(with: walletAmount, value: minimumAmount))
        }
        return nil
    }
}
