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
    
    private let node: TONNetworkNode
    private let targetType: TargetType
    
    // MARK: - Init
    
    init(node: TONNetworkNode, targetType: TargetType) {
        self.node = node
        self.targetType = targetType
    }
    
    // MARK: - TargetType
    
    var baseURL: URL {
        return node.endpoint.url
    }
    
    var path: String {
        return "jsonRPC"
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Moya.Task {
        let jrpcRequest: TONProviderRequest<Dictionary<String, String?>>
        
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
        case .sendBoc(let message):
            jrpcRequest = TONProviderRequest(
                id: UUID().uuidString,
                method: .sendBoc,
                params: ["boc": message]
            )
        case .sendBocReturnHash(let message):
            jrpcRequest = TONProviderRequest(
                id: UUID().uuidString,
                method: .sendBocReturnHash,
                params: ["boc": message]
            )
        }
        
        return .requestParameters(parameters: (try? jrpcRequest.asDictionary()) ?? [:], encoding: JSONEncoding.default)
    }
    
    var headers: [String : String]? {
        var headers: [String : String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        if let apiKeyHeaderValue = node.endpoint.apiKeyHeaderValue, let apiKeyHeaderName = node.endpoint.apiKeyHeaderName {
            headers[apiKeyHeaderName] = apiKeyHeaderValue
        }
        
        return headers
    }
    
}

extension TONProviderTarget {
    
    enum TargetType {
        case getInfo(address: String)
        case estimateFee(address: String, body: String?)
        case getBalance(address: String)
        case sendBoc(message: String)
        case sendBocReturnHash(message: String)
    }
    
}
