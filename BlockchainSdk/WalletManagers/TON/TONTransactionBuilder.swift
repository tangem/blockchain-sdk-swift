//
//  TONTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TONTransactionBuilder {
    
    // MARK: - Properties
    
    var wallet: TONWallet?
    
    // MARK: - Init
    
    init(walletPublicKey: Data) throws {
        self.wallet = try .init(publicKey: walletPublicKey)
    }
    
    // MARK: - Implementation
    
    public func buildForSign(transaction: Transaction, signer: TransactionSigner) throws -> TONCell {
        guard let signingMessage = try self.wallet?.createTransferMessage(
            address: transaction.destinationAddress,
            amount: 100,
            seqno: 333
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        return signingMessage
    }
    
    public func buildForSend(signingMessage: TONCell, seqno: Int) throws -> TONExternalMessage {
        guard let externalMessage = try self.wallet?.createExternalMessage(signingMessage: signingMessage, seqno: seqno) else {
            throw WalletError.failedToBuildTx
        }
        
        return externalMessage
    }
    
}
