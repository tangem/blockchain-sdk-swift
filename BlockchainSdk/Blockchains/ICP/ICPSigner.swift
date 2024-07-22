//
//  ICPSigner.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 08.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import IcpKit
import Combine
import WalletCore
import TangemSdk

struct ICPSigner {
    let signer: TransactionSigner
    let walletPublicKey: Wallet.PublicKey
    
    init(signer: TransactionSigner, walletPublicKey: Wallet.PublicKey) {
        self.signer = signer
        self.walletPublicKey = walletPublicKey
    }
    
    func sign(input: ICPSigningInput) -> AnyPublisher<ICPSigningOutput, Error> {
        do {
            let requestData = try makeRequestData(for: input)
            let hashesToSign = try input.hashes(requestData: requestData, domain: ICPDomainSeparator("ic-request"))
            return signer.sign(hashes: hashesToSign, walletPublicKey: walletPublicKey)
                .tryMap { signatures in
                    // assume that output hashes returned in the same order as the input ones
                    guard signatures.count == 2,
                          let callSignature = signatures.first,
                          let readStateSignature = signatures.last else {
                        throw WalletError.empty
                    }
                    return ICPSigningOutput(
                        data: requestData,
                        callSignature: callSignature,
                        readStateSignature: readStateSignature
                    )
                }
                .eraseToAnyPublisher()
        } catch {
            return .anyFail(error: error)
        }
    }
    
    private func makeRequestData(for input: ICPSigningInput) throws -> ICPRequestsData {
        guard let publicKey = PublicKey(
            tangemPublicKey: walletPublicKey.blockchainKey,
            publicKeyType: CoinType.internetComputer.publicKeyType
        ) else {
            throw WalletError.failedToBuildTx
        }
        
        return try input.makeRequestData(for: publicKey.data, nonce: try CryptoUtils.icpNonce())
    }
}
