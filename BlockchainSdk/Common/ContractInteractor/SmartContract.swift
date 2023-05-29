//
//  SmartContract.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 15.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol SmartContract {
    associatedtype MethodType: SmartContractMethodType
    
    var address: String { get }
    var abi: String { get }
    var providers: [SmartContractRPCProvider] { get }
}
