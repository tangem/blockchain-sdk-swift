//
//  WalletCoreABIEncoder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

struct WalletCoreABIEncoder: ABIEncoder {
    func encode(method: SmartContractMethodType) -> String {
        let function = EthereumAbiFunction(name: method.name)
        for parameter in method.parameters {
            switch parameter {
            case .bytes(let data):
                function.addParamBytes(val: data, isOutput: false)
            }
        }
        
        let encodedData = EthereumAbi.encode(fn: function)

        return encodedData.hexString.addHexPrefix()
    }
}
