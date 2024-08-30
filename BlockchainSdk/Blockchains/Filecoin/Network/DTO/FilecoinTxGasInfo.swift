//
//  FilecoinTxGasInfo.swift
//  BlockchainSdk
//
//  Created by Aleksei Muraveinik on 27.08.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BigInt

struct FilecoinTxGasInfo: Decodable {
    let gasUnitPrice: BigUInt
    let gasLimit: BigUInt
    let gasPremium: BigUInt
}
