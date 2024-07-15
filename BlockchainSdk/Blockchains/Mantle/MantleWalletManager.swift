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

final class MantleWalletManager: EthereumWalletManager {
    // This is a workaround for sending a Mantle transaction.
    // Unfortunately, Mantle's current implementation does not conform to our existing fee calculation rules.
    // https://tangem.slack.com/archives/GMXC6PP71/p1719591856597299?thread_ts=1714215815.690169&cid=GMXC6PP71
    override func getFee(amount: Amount, destination: String) -> AnyPublisher<[Fee], any Error> {
        let blockchain = wallet.blockchain
        let decimalValue = blockchain.decimalValue
        let amount = Amount(
            with: wallet.blockchain,
            type: amount.type,
            value: amount.value - (1 / decimalValue)
        )
        
        return super.getFee(amount: amount, destination: destination)
            .tryMap { fees in
                try fees.map { fee in
                    guard var parameters = fee.parameters as? EthereumEIP1559FeeParameters else {
                        throw WalletError.failedToGetFee
                    }
                    
                    parameters = EthereumEIP1559FeeParameters(
                        gasLimit: BigUInt(ceil(Double(parameters.gasLimit) * 1.6)),
                        maxFeePerGas: parameters.maxFeePerGas,
                        priorityFee: parameters.priorityFee
                    )
                    
                    let feeValue = parameters.calculateFee(decimalValue: decimalValue)
                    let amount = Amount(with: blockchain, value: feeValue)

                    return Fee(amount, parameters: parameters)
                }
            }
            .eraseToAnyPublisher()
    }
}
