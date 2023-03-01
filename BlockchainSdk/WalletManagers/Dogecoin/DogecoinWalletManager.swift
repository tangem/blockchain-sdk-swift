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
            
            let secpSignatureSize = 64
            let signatures = hashes.map { _ in Data(repeating: 1, count: secpSignatureSize) }
            
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

        // Minimal fee is too small, increase it several times fold to make the transaction confirm faster.
        // It's still going to be under 1 DOGE
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
