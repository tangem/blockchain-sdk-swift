//
//  SignatureUtils.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 03.09.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemSdk

enum SignatureUtils {
    static func unmarshalledSignature(from originalSignature: Data, publicKey: Data, hash: Data) throws -> Data {
        let signature = try Secp256k1Signature(with: originalSignature)
        let unmarshalledSignature = try signature.unmarshal(with: publicKey, hash: hash)

        guard unmarshalledSignature.v.count == Constants.recoveryIdLength else {
            throw WalletError.failedToBuildTx
        }

        let recoveryId = unmarshalledSignature.v[0] - Constants.recoveryIdDiff

        guard recoveryId >= Constants.recoveryIdLowerBound, recoveryId <= Constants.recoveryIdUpperBound else {
            throw WalletError.failedToBuildTx
        }

        return unmarshalledSignature.r + unmarshalledSignature.s + Data(recoveryId)
    }
}

private extension SignatureUtils {
    enum Constants {
        static let recoveryIdLength = 1
        static let recoveryIdDiff: UInt8 = 27
        static let recoveryIdLowerBound: UInt8 = 0
        static let recoveryIdUpperBound: UInt8 = 3
    }

}
