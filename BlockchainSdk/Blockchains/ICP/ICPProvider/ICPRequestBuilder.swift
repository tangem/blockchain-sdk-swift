//
//  ICPRequestBuilder.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum ICPRequestBuilder {
    static let defaultIngressExpirySeconds: TimeInterval = 4 * 60 // 4 minutes
    
    static func buildContent(_ request: ICPRequest, sender: ICPPrincipal? = nil) throws -> ICPRequestContent {
        let nonce = try CryptoUtils.generateRandomBytes(count: 32)
        let ingressExpiry = createIngressExpiry()
        let senderBytes = sender?.bytes ?? Data([4])
        
        switch request {
        case .readState(let paths):
            let encodedPaths = paths.map { $0.encodedComponents() }
            return ICPReadStateRequestContent(
                request_type: .readState,
                sender: senderBytes,
                nonce: nonce,
                ingress_expiry: ingressExpiry,
                paths: encodedPaths
            )
            
        case .call(let method), .query(let method):
            let serialisedArgs = CandidSerialiser().encode(method.args)
            return ICPCallRequestContent(
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
    
    static func buildEnvelope(_ content: ICPRequestContent, sender: ICPSigningPrincipal?) async throws -> ICPRequestEnvelope {
        guard let sender else {
            return ICPRequestEnvelope(content: content)
        }
        let requestId = try content.calculateRequestId()
        let domain = ICPDomainSeparator("ic-request")
        
        let domainSeparatedData = domain.domainSeparatedData(requestId)
        let hashedMessage = domainSeparatedData.getSha256()
        
        let senderSignature = try await sender.sign(requestId, domain: "ic-request")
        let senderPublicKey = sender.rawPublicKey
        return ICPRequestEnvelope(
            content: content,
            senderPubkey: senderPublicKey,
            senderSig: senderSignature
        )
    }
    
    private static func createIngressExpiry(_ seconds: TimeInterval = defaultIngressExpirySeconds) -> Int {
        let expiryDate = Date().addingTimeInterval(defaultIngressExpirySeconds)
        let nanoSecondsSince1970 = expiryDate.timeIntervalSince1970 * 1_000_000_000
        return Int(nanoSecondsSince1970)
    }
    
    
}
