//
//  TronTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

enum TronTarget: TargetType {
    case getAccount(address: String, network: TronNetwork)
    case createTransaction(source: String, destination: String, amount: UInt64, network: TronNetwork)
    case createTrc20Transaction(source: String, destination: String, contractAddress: String, amount: UInt64, network: TronNetwork)
    case broadcastTransaction(transaction: TronTransactionRequest, network: TronNetwork)
    case broadcastTransaction2(transaction: TronTransactionRequest2, network: TronNetwork)
    case tokenBalance(address: String, contractAddress: String, network: TronNetwork)
    case tokenTransactionHistory(contractAddress: String, limit: Int, network: TronNetwork)
    
    var baseURL: URL {
        switch self {
        case .getAccount(_, let network):
            return network.url
        case .createTransaction(_, _, _, let network):
            return network.url
        case .createTrc20Transaction(_, _, _, _, let network):
            return network.url
        case .broadcastTransaction(_, let network):
            return network.url
        case .broadcastTransaction2(_, let network):
            return network.url
        case .tokenBalance(_, _, let network):
            return network.url
        case .tokenTransactionHistory(_, _, let network):
            return network.url
        }
    }
    
    var path: String {
        switch self {
        case .getAccount:
            return "/wallet/getaccount"
        case .createTransaction:
            return "/wallet/createtransaction"
        case .broadcastTransaction, .broadcastTransaction2:
            return "/wallet/broadcasttransaction"
        case .createTrc20Transaction, .tokenBalance:
            return "/wallet/triggersmartcontract"
        case .tokenTransactionHistory(let contractAddress, _, _):
            return "/v1/contracts/\(contractAddress)/transactions"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .tokenTransactionHistory:
            return .get
        default:
            return .post
        }
    }
    
    var task: Task {
        let encoder = JSONEncoder()
        
        do {
            switch self {
            case .getAccount(let address, _):
                let request = TronGetAccountRequest(address: address, visible: true)
                return .requestData(try encoder.encode(request))
            case .createTransaction(let source, let destination, let amount, _):
                let request = TronCreateTransactionRequest(owner_address: source, to_address: destination, amount: amount, visible: true)
                return .requestData(try encoder.encode(request))
            case .createTrc20Transaction(let source, let destination, let contractAddress, let amount, _):
                let hexAddress = TronAddressService.toHexForm(destination, length: 64) ?? ""
                let hexAmount = String(repeating: "0", count: 48) + Data(Data(from: amount).reversed()).hex
                let parameter = hexAddress + hexAmount
                
                let request = TronTriggerSmartContractRequest(
                    owner_address: source,
                    contract_address: contractAddress,
                    function_selector: "transfer(address,uint256)",
                    fee_limit: 10000000,
                    call_value: 0,
                    parameter: parameter,
                    visible: true
                )
                return .requestData(try encoder.encode(request))
            case .broadcastTransaction(let transaction, _):
                return .requestData(try encoder.encode(transaction))
            case .broadcastTransaction2(let transaction, _):
                return .requestData(try encoder.encode(transaction))
            case .tokenBalance(let address, let contractAddress, _):
                let hexAddress = TronAddressService.toHexForm(address, length: 64) ?? ""
                
                let request = TronTriggerSmartContractRequest(
                    owner_address: address,
                    contract_address: contractAddress,
                    function_selector: "balanceOf(address)",
                    fee_limit: 10000000,
                    call_value: 0,
                    parameter: hexAddress,
                    visible: true
                )
                return .requestData(try encoder.encode(request))
            case .tokenTransactionHistory(_, let limit, _):
                let parameters: [_: Any] = [
                    "only_confirmed": true,
                    "limit": limit,
                ]
                return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
            }
        } catch {
            print("Failed to encode Tron request data:", error)
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
    }
}
