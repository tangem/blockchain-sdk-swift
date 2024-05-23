//
//  EthereumFeeParameters.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BigInt

public struct EthereumEIP1559FeeParameters: FeeParameters {
    public let gasLimit: BigUInt
    /// Maxumum fee whick will be spend. Should inclued `priorityFee` in itself
    public let maxFeePerGas: BigUInt
    /// The part of `maxFeePerGas` which will be sent a mainer like a tips
    public let priorityFee: BigUInt

    public init(gasLimit: BigUInt, baseFee: BigUInt, priorityFee: BigUInt) {
        self.gasLimit = gasLimit
        self.maxFeePerGas = baseFee + priorityFee
        self.priorityFee = priorityFee
    }

    public init(gasLimit: BigUInt, maxFeePerGas: BigUInt, priorityFee: BigUInt) {
        self.gasLimit = gasLimit
        self.maxFeePerGas = maxFeePerGas
        self.priorityFee = priorityFee
    }

    public func caclulateFee(decimalValue: Decimal) -> Decimal {
        let feeWEI = gasLimit * maxFeePerGas
        // TODO: Fix integer overflow. Think about BigInt
        // https://tangem.atlassian.net/browse/IOS-4268
        // https://tangem.atlassian.net/browse/IOS-5119
        let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))
        return feeValue / decimalValue
    }
}
