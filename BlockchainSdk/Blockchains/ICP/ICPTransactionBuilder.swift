//
//  ICPTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore
import IcpKit
import Combine

final class ICPTransactionBuilder {
    // MARK: - Private Properties
    
    private let decimalValue: Decimal
    private let publicKey: Data
    private let nonce: () throws -> Data
    
    // MARK: - Init
    
    init(decimalValue: Decimal, publicKey: Data, nonce: @autoclosure @escaping () throws -> Data) {
        self.decimalValue = decimalValue
        self.publicKey = publicKey
        self.nonce = nonce
    }
    
    // MARK: - Implementation
    
    /// Build input for sign transaction
    /// - Parameters:
    ///   - transaction: Transaction
    ///   - date: current timestamp
    /// - Returns: ICPSigningInput for sign transaction with external signer
    public func buildForSign(
        transaction: Transaction,
        date: Date = Date()
    ) throws -> ICPSigningInput {
        guard let publicKey = PublicKey(
            tangemPublicKey: publicKey,
            publicKeyType: CoinType.internetComputer.publicKeyType
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        let transactionParams = ICPTransactionParams(
            destination: Data(hex: transaction.destinationAddress),
            amount: (transaction.amount.value * decimalValue).uint64Value,
            date: date
        )
        
        return try ICPSigningInput(
            publicKey: publicKey.data,
            nonce: nonce,
            domainSeparator: "ic-request",
            transactionParams: transactionParams
        )
    }
    
    /// Build for send transaction obtain external message output
    /// - Parameters:
    ///   - ouput: IcpKit provided request envelope
    /// - Returns: cbor-encoded transaction Data
    public func buildForSend(signedHashes: [Data], requestData: ICPRequestsData) throws -> ICPSigningOutput {
        guard signedHashes.count == 2,
              let callSignature = signedHashes.first,
              let readStateSignature = signedHashes.last else {
            throw WalletError.empty
        }
        return try ICPSigningOutput(
            data: requestData,
            callSignature: callSignature,
            readStateSignature: readStateSignature
        )
    }
}
