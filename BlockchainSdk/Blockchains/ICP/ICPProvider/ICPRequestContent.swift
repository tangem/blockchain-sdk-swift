//
//  ICPRequestContent.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol ICPRequestContent: Encodable {
    var request_type: ICPRequestType { get }
    var sender: Data { get }
    var nonce: Data { get }
    var ingress_expiry: Int { get }
}

struct ReadStateRequestContent: ICPRequestContent {
    let request_type: ICPRequestType
    let sender: Data
    let nonce: Data
    let ingress_expiry: Int
    
    let paths: [[Data]]
}

struct CallRequestContent: ICPRequestContent {
    let request_type: ICPRequestType
    let sender: Data
    let nonce: Data
    let ingress_expiry: Int
    
    let method_name: String
    let canister_id: Data
    let arg: Data
}

enum ICPRequestType: String, Encodable {
    case call       = "call"
    case query      = "query"
    case readState  = "read_state"
    
    static func from(_ request: ICPRequest) -> ICPRequestType {
        switch request {
        case .call: return .call
        case .query: return .query
        case .readState: return .readState
        }
    }
}


