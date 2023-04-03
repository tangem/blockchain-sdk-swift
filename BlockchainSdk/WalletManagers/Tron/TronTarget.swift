//
//  TronTarget.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 24.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TronTarget: TargetType {
    enum TronTargetType {
        case getChainParameters(network: TronNetwork)
        case getAccount(address: String, network: TronNetwork)
        case getAccountResource(address: String, network: TronNetwork)
        case getNowBlock(network: TronNetwork)
        case broadcastHex(data: Data, network: TronNetwork)
        case tokenBalance(address: String, contractAddress: String, network: TronNetwork)
        case contractEnergyUsage(sourceAddress: String, contractAddress: String, parameter: String, network: TronNetwork)
        case getTransactionInfoById(transactionID: String, network: TronNetwork)
    }
    
    let type: TronTargetType
    
    init(_ type: TronTargetType) {
        self.type = type
    }
    
    var baseURL: URL {
        type.network.url
    }
    
    var path: String {
        switch type {
        case .getChainParameters:
            return "/wallet/getchainparameters"
        case .getAccount:
            return "/wallet/getaccount"
        case .getAccountResource:
            return "/wallet/getaccountresource"
        case .getNowBlock:
            return "/wallet/getnowblock"
        case .broadcastHex:
            return "/wallet/broadcasthex"
        case .tokenBalance, .contractEnergyUsage:
            return "/wallet/triggerconstantcontract"
        case .getTransactionInfoById:
            return "/walletsolidity/gettransactioninfobyid"
        }
    }
    
    var method: Moya.Method {
        .post
    }
    
    var task: Task {
        switch type {
        case .getChainParameters:
            return .requestPlain
        case .getAccount(let address, _), .getAccountResource(let address, _):
            let request = TronGetAccountRequest(address: address, visible: true)
            return .requestJSONEncodable(request)
        case .getNowBlock:
            return .requestPlain
        case .broadcastHex(let data, _):
            let request = TronBroadcastRequest(transaction: data.hex)
            return .requestJSONEncodable(request)
        case .tokenBalance(let address, let contractAddress, _):
            let hexAddress = TronAddressService.toHexForm(address, length: 64) ?? ""
            
            let request = TronTriggerSmartContractRequest(
                owner_address: address,
                contract_address: contractAddress,
                function_selector: "balanceOf(address)",
                parameter: hexAddress,
                visible: true
            )
            return .requestJSONEncodable(request)
        case .contractEnergyUsage(let sourceAddress, let contractAddress, let parameter, _):
            let request = TronTriggerSmartContractRequest(
                owner_address: sourceAddress,
                contract_address: contractAddress,
                function_selector: "transfer(address,uint256)",
                parameter: parameter,
                visible: true
            )
            return .requestJSONEncodable(request)
        case .getTransactionInfoById(let transactionID, _):
            let request = TronTransactionInfoRequest(value: transactionID)
            return .requestJSONEncodable(request)
        }
    }
    
    var headers: [String : String]? {
        var headers = [
            "Accept": "application/json",
            "Content-Type": "application/json",
        ]
        
        if let apiKeyHeaderName = type.network.apiKeyHeaderName, let apiKeyHeaderValue = type.network.apiKeyHeaderValue {
            headers[apiKeyHeaderName] = apiKeyHeaderValue
        }
        
        return headers
    }
}

fileprivate extension TronTarget.TronTargetType {
    var network: TronNetwork {
        switch self {
        case .getChainParameters(let network):
            return network
        case .getAccount(_, let network):
            return network
        case .getAccountResource(_, let network):
            return network
        case .getNowBlock(let network):
            return network
        case .broadcastHex(_, let network):
            return network
        case .tokenBalance(_, _, let network):
            return network
        case .contractEnergyUsage(_, _, _, let network):
            return network
        case .getTransactionInfoById(_, let network):
            return network
        }
    }
}
