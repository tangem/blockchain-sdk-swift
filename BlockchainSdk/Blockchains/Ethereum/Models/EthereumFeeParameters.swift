//
//  EthereumFeeParameters.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BigInt

public struct EthereumFeeParameters: FeeParameters {
    public let gasLimit: BigUInt
    public let gasPrice: BigUInt

    public init(gasLimit: BigUInt, gasPrice: BigUInt) {
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
    }

    public func caclulateFee(decimalValue: Decimal) -> Decimal {
        let feeWEI = gasLimit * gasPrice
        // TODO: Fix integer overflow. Think about BigInt
        // https://tangem.atlassian.net/browse/IOS-4268
        // https://tangem.atlassian.net/browse/IOS-5119
        let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))
        return feeValue / decimalValue
    }
}

public struct EthereumEIP1559FeeParameters: FeeParameters {
    public let gasLimit: BigUInt
    public let baseFee: BigUInt
    public let priorityFee: BigUInt

    public init(gasLimit: BigUInt, baseFee: BigUInt, priorityFee: BigUInt) {
        self.gasLimit = gasLimit
        self.baseFee = baseFee
        self.priorityFee = priorityFee
    }

    public func caclulateFee(decimalValue: Decimal) -> Decimal {
        let feeWEI = gasLimit * (baseFee + priorityFee)
        // TODO: Fix integer overflow. Think about BigInt
        // https://tangem.atlassian.net/browse/IOS-4268
        // https://tangem.atlassian.net/browse/IOS-5119
        let feeValue = feeWEI.decimal ?? Decimal(UInt64(feeWEI))
        return feeValue / decimalValue
    }
}
