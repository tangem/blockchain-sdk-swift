//
//  DogecoinWalletManager.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 25/05/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

class DogecoinWalletManager: BitcoinWalletManager {
    override var minimalFee: Decimal { 0.01 }
    override var minimalFeePerByte: Decimal {
        let dogePerKiloByte: Decimal = 0.01
        let bytesInKiloByte: Decimal = 1024
        
        return dogePerKiloByte / bytesInKiloByte
    }
    
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Amount], Error> {
        // https://github.com/dogecoin/dogecoin/blob/master/doc/fee-recommendation.md
        
        let satoshiPerByte = minimalFeePerByte * wallet.blockchain.decimalValue
        
        let satoshiPerByteInteger = (satoshiPerByte.rounded(roundingMode: .up) as NSDecimalNumber).intValue
        
        let transactionSize: Int
        do {
            let changeScript = txBuilder.changeScript
            let hashes = try txBuilder.bitcoinManager.buildForSign(
                target: destination,
                amount: amount.value,
                feeRate: satoshiPerByteInteger,
                changeScript: changeScript
            )
            
            let signer = DummySigner()
            let signatures = try hashes.map {
                try signer.sign(hash: $0, walletPublicKey: signer.publicKey)
            }
            
            let transactionData = try txBuilder.bitcoinManager.buildForSend(
                target: destination,
                amount: amount.value,
                feeRate: satoshiPerByteInteger,
                derSignatures: signatures,
                changeScript: changeScript
            )
            transactionSize = transactionData.count
        } catch {
            print("Failed to calculate \(wallet.blockchain.displayName) fee", error)
            return .anyFail(error: BlockchainSdkError.failedToLoadFee)
        }
        
        let minSatoshiFee = Decimal(integerLiteral: satoshiPerByteInteger * transactionSize) / wallet.blockchain.decimalValue

        let normalSatoshiFee = minSatoshiFee * 10
        let maxSatoshiFee = minSatoshiFee * 100
        
        let feeAmounts = [minSatoshiFee, normalSatoshiFee, maxSatoshiFee]
            .map {
                Amount(with: wallet.blockchain, value: $0)
            }
        
        return Just(feeAmounts)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

extension DogecoinWalletManager: DustRestrictable {
    var dustValue: Amount {
        .init(with: wallet.blockchain, value: minimalFee)
    }
}

fileprivate class DummySigner {
    let privateKey: Data
    let publicKey: Wallet.PublicKey
    
    init() {
        let keyPair = try! Secp256k1Utils().generateKeyPair()
        let compressedPublicKey = try! Secp256k1Key(with: keyPair.publicKey).compress()
        self.publicKey = Wallet.PublicKey(seedKey: compressedPublicKey, derivedKey: nil, derivationPath: nil)
        self.privateKey = keyPair.privateKey
    }
    
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) throws -> Data {
        let signature = try Secp256k1Utils().sign(hash, with: privateKey)
        return signature
    }
}
