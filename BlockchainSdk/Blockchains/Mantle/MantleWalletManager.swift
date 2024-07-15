//
//  MantleWalletManager.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 15.07.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt
import Combine
import Foundation

// This is a workaround for sending a Mantle transaction.
// Unfortunately, Mantle's current implementation does not conform to our existing fee calculation rules.
// https://tangem.slack.com/archives/GMXC6PP71/p1719591856597299?thread_ts=1714215815.690169&cid=GMXC6PP71
final class MantleWalletManager: EthereumWalletManager {
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        let blockchain = wallet.blockchain
        let decimalValue = blockchain.decimalValue
        let amount = Amount(
            with: wallet.blockchain,
            type: amount.type,
            value: amount.value - (1 / decimalValue)
        )
        
        return super.getFee(amount: amount, destination: destination)
            .withWeakCaptureOf(self)
            .tryMap { walletManager, fees in
                try fees.map { fee in
                    try walletManager.mapMantleFee(fee, gasLimitMultiplier: 1.6)
                }
            }
            .eraseToAnyPublisher()
    }
    
    override func sign(_ transaction: Transaction, signer: any TransactionSigner) -> AnyPublisher<String, any Error> {
        Result {
            var transaction = transaction
            transaction.fee = try mapMantleFee(transaction.fee, gasLimitMultiplier: 0.7)
            return transaction
        }
        .publisher
        .flatMap { transaction in
            super.sign(transaction, signer: signer)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension MantleWalletManager {
    func mapMantleFee(_ fee: Fee, gasLimitMultiplier: Double) throws -> Fee {
        let parameters: any EthereumFeeParameters = switch fee.parameters {
        case let parameters as EthereumEIP1559FeeParameters:
            EthereumEIP1559FeeParameters(
                gasLimit: BigUInt(ceil(Double(parameters.gasLimit) * gasLimitMultiplier)),
                maxFeePerGas: parameters.maxFeePerGas,
                priorityFee: parameters.priorityFee
            )
        case let parameters as EthereumLegacyFeeParameters:
            EthereumLegacyFeeParameters(
                gasLimit: BigUInt(ceil(Double(parameters.gasLimit) * gasLimitMultiplier)),
                gasPrice: parameters.gasPrice
            )
        default:
            throw WalletError.failedToGetFee
        }
        
        let blockchain = wallet.blockchain
        let feeValue = parameters.calculateFee(decimalValue: blockchain.decimalValue)
        let amount = Amount(with: blockchain, value: feeValue)

        return Fee(amount, parameters: parameters)
    }
}
