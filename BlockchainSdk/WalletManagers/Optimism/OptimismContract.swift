//
//  OptimismContract.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 08.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

public struct OptimismContract: SmartContract {
    public typealias MethodType = ContractMethod
    
    public let rpcURL: URL
    public var address: String { "0x420000000000000000000000000000000000000F" }
    
    public init(rpcURL: URL) {
        self.rpcURL = rpcURL
    }
}

public extension OptimismContract {
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

extension OptimismContract {
    public var abi: String {
        let bundle = Bundle(for: BaseManager.self)
        let url = bundle.url(forResource: "OptimismSmartContractABI", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let string = String(bytes: data, encoding: .utf8)!
        
        let string2 = """
            [{"inputs":[{"internalType":"address","name":"_owner","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"DecimalsUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"GasPriceUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"L1BaseFeeUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"OverheadUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"","type":"uint256"}],"name":"ScalarUpdated","type":"event"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"gasPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"getL1Fee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"getL1GasUsed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"l1BaseFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"overhead","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"scalar","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_decimals","type":"uint256"}],"name":"setDecimals","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_gasPrice","type":"uint256"}],"name":"setGasPrice","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_baseFee","type":"uint256"}],"name":"setL1BaseFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_overhead","type":"uint256"}],"name":"setOverhead","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_scalar","type":"uint256"}],"name":"setScalar","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"}]
            """
        assert(string == string2)

        return string2
    }
}
