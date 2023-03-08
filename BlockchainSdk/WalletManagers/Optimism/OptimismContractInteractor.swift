//
//  OptimismContractInteractor.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 08.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine

protocol OptimismNetworkProvider {
    func getLayer1Fee(data: String) -> AnyPublisher<Decimal, Error>
}

struct OptimismContractInteractor {
    private let contractInteractor: ContractInteractor

    init(rpcURL: URL) {
        contractInteractor = ContractInteractor(
           address: "0x420000000000000000000000000000000000000F",
           abi: ContractABI().optimismLayer1GasFeeABI,
           rpcURL: rpcURL
       )
    }
    
    func read(method: ContractMethod) -> AnyPublisher<Any, Error>  {
        contractInteractor
            .read(method: method.name, parameters: method.parameters)
    }
}

extension OptimismContractInteractor {
    enum ContractMethod {
        /// Return a value which equal result the `getL1GasUsed` multiplied on `l1BaseFee`
        case getL1Fee(data: String)

        /// Like the gasLimit related the transaction data size
        case getL1GasUsed(data: String)
        
        /// Like the gasPrice
        case l1BaseFee
        
        var name: String {
            switch self {
            case .getL1Fee:
                return "getL1Fee"
            case .getL1GasUsed:
                return "getL1GasUsed"
            case .l1BaseFee:
                return "l1BaseFee"
            }
        }
        
        var parameters: [AnyObject] {
            switch self {
            case .getL1Fee(data: let data):
                return [data as AnyObject]
            case .getL1GasUsed(data: let data):
                return [data as AnyObject]
            case .l1BaseFee:
                return []
            }
        }
    }
}

