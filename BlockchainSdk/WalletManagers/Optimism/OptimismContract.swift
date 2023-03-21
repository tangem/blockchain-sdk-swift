//
//  OptimismSmartContract.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 08.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

public struct OptimismSmartContract: SmartContract {
    public typealias MethodType = ContractMethod
    
    public let rpcURL: URL
    public var address: String { "0x420000000000000000000000000000000000000F" }
    public var abi: String { OptimismSmartContractABI().abi }
    
    public init(rpcURL: URL) {
        self.rpcURL = rpcURL
    }
}

public extension OptimismSmartContract {
    enum ContractMethod: SmartContractMethodType {
        /// Return a value which equal result the `getL1GasUsed` multiplied on `l1BaseFee`
        case getL1Fee(data: String)

        /// Like the gasLimit related the transaction data size
        case getL1GasUsed(data: String)
        
        /// Like the gasPrice
        case l1BaseFee
        
        public var name: String {
            switch self {
            case .getL1Fee:
                return "getL1Fee"
            case .getL1GasUsed:
                return "getL1GasUsed"
            case .l1BaseFee:
                return "l1BaseFee"
            }
        }
        
        public var parameters: [AnyObject] {
            switch self {
            case .getL1Fee(let data):
                return [data as AnyObject]
            case .getL1GasUsed(let data):
                return [data as AnyObject]
            case .l1BaseFee:
                return []
            }
        }
    }
}
