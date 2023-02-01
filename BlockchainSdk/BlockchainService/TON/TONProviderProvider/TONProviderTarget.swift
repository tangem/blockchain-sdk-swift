//
//  TONProviderTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TONProviderTarget: TargetType {
    
    // MARK: - Properties
    
    private(set) var host: String
    private(set) var targetType: TargetType
    
    // MARK: - TargetType
    
    var baseURL: URL {
        return URL(string: host)!
    }
    
    var path: String {
        return "jsonRPC"
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Moya.Task {
        var jrpcRequest: TONProviderRequest<Dictionary<String, String?>>?
        
        switch targetType {
        case .getInfo(let address):
            jrpcRequest = TONProviderRequest(
                id: UUID().uuidString,
                method: .getWalletInformation,
                params: ["address": address]
            )
        case .getBalance(let address):
            jrpcRequest = TONProviderRequest(
                id: UUID().uuidString,
                method: .getAddressBalance,
                params: ["address": address]
            )
        case .estimateFee(let address, let body):
            jrpcRequest = TONProviderRequest(
                id: UUID().uuidString,
                method: .estimateFee,
                params: ["address": address, "body": body]
            )
        case .estimateFeeWithCode(let address, let body, let initCode, let initData):
            jrpcRequest = TONProviderRequest(
                id: UUID().uuidString,
                method: .estimateFee,
                params: ["address": address, "body": body, "init_code": initCode, "init_data": initData]
            )
        case .sendBoc(let message):
            jrpcRequest = TONProviderRequest(
                id: UUID().uuidString,
                method: .sendBoc,
                params: ["boc": message]
            )
        }
        
        return .requestParameters(parameters: (try? jrpcRequest?.asDictionary()) ?? [:], encoding: JSONEncoding.default)
    }
    
    var headers: [String : String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-API-KEY": "21e8fb0fa0b6a4dcb14524489fd22c8b8904209fa9df19b227d7b8b30ca22de9"
        ]
    }
    
}

extension TONProviderTarget {
    
    public enum TargetType {
        case getInfo(address: String)
        case estimateFee(address: String, body: String?)
        case estimateFeeWithCode(address: String, body: String?, initCode: String?, initData: String?)
        case getBalance(address: String)
        case sendBoc(message: String)
    }
    
}
