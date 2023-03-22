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
import BitcoinCore

class DogecoinWalletManager: BitcoinWalletManager {
    override var minimalFee: Decimal { 0.01 }
    override var minimalFeePerByte: Decimal {
        let dogePerKiloByte: Decimal = 0.01
        let bytesInKiloByte: Decimal = 1024
        
        return dogePerKiloByte / bytesInKiloByte
    }
    
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], Error> {
        // https://github.com/dogecoin/dogecoin/blob/master/doc/fee-recommendation.md
        
        let recommendedSatoshiPerByteDecimal = minimalFeePerByte * wallet.blockchain.decimalValue
        let recommendedSatoshiPerByte = (recommendedSatoshiPerByteDecimal.rounded(roundingMode: .up) as NSDecimalNumber).intValue
        
        let transactionSize: Int
        do {
            let changeScript = txBuilder.changeScript
            let hashes = try txBuilder.bitcoinManager.buildForSign(
                target: destination,
                amount: amount.value,
                feeRate: recommendedSatoshiPerByte,
                changeScript: changeScript
            )
            
            let secpSignatureSize = 64
            let signatures = hashes.map { _ in Data(repeating: 1, count: secpSignatureSize) }
            
            let transactionData = try txBuilder.bitcoinManager.buildForSend(
                target: destination,
                amount: amount.value,
                feeRate: recommendedSatoshiPerByte,
                derSignatures: signatures,
                changeScript: changeScript
            )
            transactionSize = transactionData.count
        } catch {
            if let bitcoinCoreError = error as? BitcoinCoreErrors.SendValueErrors,
               case .dust = bitcoinCoreError {
                return .justWithError(output: [Fee(.zeroCoin(for: wallet.blockchain))])
            }
            
            print("Failed to calculate \(wallet.blockchain.displayName) fee", error)
            return .anyFail(error: BlockchainSdkError.failedToLoadFee)
        }
        
        func fee(for rate: Int) -> Decimal {
            return Decimal(integerLiteral: rate * transactionSize) / wallet.blockchain.decimalValue
        }

        // Minimal fee is too small, increase it several times fold to make the transaction confirm faster.
        // It's still going to be under 1 DOGE
        let minRate = recommendedSatoshiPerByte
        let normalRate = recommendedSatoshiPerByte * 10
        let maxRate = recommendedSatoshiPerByte * 100
        
        let minFee = fee(for: minRate)
        let normalFee = fee(for: normalRate)
        let maxFee = fee(for: maxRate)

        let fees = [minFee, normalFee, maxFee]
            .map { Amount(with: wallet.blockchain, value: $0) }
            .map { Fee($0) }
        
        txBuilder.feeRates = [:]
        txBuilder.feeRates[minFee] = minRate
        txBuilder.feeRates[normalFee] = normalRate
        txBuilder.feeRates[maxFee] = maxRate
        
        return Just(fees)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

extension DogecoinWalletManager: DustRestrictable {
    var dustValue: Amount {
        .init(with: wallet.blockchain, value: minimalFee)
    }
}
