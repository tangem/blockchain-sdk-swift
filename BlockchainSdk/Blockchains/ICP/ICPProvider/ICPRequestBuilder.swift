//
//  ICPRequestBuilder.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum ICPRequestBuilder {
    static let defaultIngressExpirySeconds: TimeInterval = 4 * 60 // 4 minutes
    
    static func buildContent(_ request: ICPRequest) throws -> ICPRequestContent {
        let nonce = Data.init(repeating: 0, count: 32) // FIXME: 
        let ingressExpiry = createIngressExpiry()
        let senderBytes = Data([4])
        
        switch request {
        case .readState(let paths):
            let encodedPaths = paths.map { $0.encodedComponents() }
            return ReadStateRequestContent(
                request_type: .readState,
                sender: senderBytes,
                nonce: nonce,
                ingress_expiry: ingressExpiry,
                paths: encodedPaths
            )
        case .call(let method), .query(let method):
            let serialisedArgs = CandidSerialiser().encode(method.args)
            return CallRequestContent(
                request_type: .from(request),
                sender: senderBytes,
                nonce: nonce,
                ingress_expiry: ingressExpiry,
                method_name: method.methodName,
                canister_id: method.canister.bytes,
                arg: serialisedArgs
            )
        
        }
    }
    
    private static func createIngressExpiry(_ seconds: TimeInterval = defaultIngressExpirySeconds) -> Int {
        let expiryDate = Date().addingTimeInterval(defaultIngressExpirySeconds)
        let nanoSecondsSince1970 = expiryDate.timeIntervalSince1970 * 1_000_000_000
        return Int(nanoSecondsSince1970)
    }
}
