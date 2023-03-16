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
}
