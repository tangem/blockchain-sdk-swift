//
//  TONProvirerTarget.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TONProvirerTarget: TargetType {
    
    // MARK: - Properties
    
    private(set) var host: String
    private(set) var targetType: TargetType
    
    // MARK: - TargetType
    
    var baseURL: URL {
        return URL(string: host)!
    }
    
    var path: String {
        switch targetType {
        case .getBalance:
            return "getAddressBalance"
        case .estimateFee:
            return "estimateFee"
        case .seqno:
            return ""
        case .sendBoc:
            return "sendBoc"
        }
    }
    
    var method: Moya.Method {
        switch targetType {
        case .getBalance:
            return .get
        case .estimateFee:
            return .post
        case .seqno:
            return .post
        case .sendBoc:
            return .post
        }
    }
    
    var task: Moya.Task {
        var parameters = Dictionary<String, Any>()
        var encoding: ParameterEncoding = JSONEncoding.default
        
        switch targetType {
        case .getBalance(let address):
            parameters["address"] = address
            encoding = URLEncoding.default
        case .estimateFee(let message):
            if message.code != nil {
                parameters["address"] = message.address.toString()
                parameters["body"] = try? Data(message.body.toBoc(false)).base64EncodedString()
                parameters["init_code"] = try? Data(message.code?.toBoc(false) ?? [UInt8]()).base64EncodedString()
                parameters["init_data"] = try? Data(message.data?.toBoc(false) ?? [UInt8]()).base64EncodedString()
            } else {
                parameters["address"] = message.address.toString()
                parameters["body"] = try? Data(message.body.toBoc(false)).base64EncodedString()
            }
            encoding = JSONEncoding.default
        case .seqno:
            break
        case .sendBoc(let message):
            let boc = try? Data(message.message.toBoc(false)).base64EncodedString()
            print(boc ?? "")
            parameters["body"] = boc
        }
        
        return .requestParameters(parameters: parameters, encoding: encoding)
    }
    
    var headers: [String : String]? {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-API-KEY": "21e8fb0fa0b6a4dcb14524489fd22c8b8904209fa9df19b227d7b8b30ca22de9"
        ]
    }
    
}

extension TONProvirerTarget {
    
    public enum TargetType {
        case estimateFee(message: TONExternalMessage)
        case getBalance(address: String)
        case seqno
        case sendBoc(message: TONExternalMessage)
    }
    
}
