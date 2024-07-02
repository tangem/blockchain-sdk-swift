//
//  ICPRequestEnvelope.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct ICPRequestEnvelope: Encodable {
    let content: ICPRequestContent
    let senderPubkey: Data?
    let senderSig: Data?
    
    init(content: ICPRequestContent, senderPubkey: Data? = nil, senderSig: Data? = nil) {
        self.content = content
        self.senderPubkey = senderPubkey
        self.senderSig = senderSig
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let readStateContent = content as? ICPReadStateRequestContent {
            try container.encode(readStateContent, forKey: .content)
        } else if let callContent = content as? ICPCallRequestContent {
            try container.encode(callContent, forKey: .content)
        } else {
            throw ICPRequestEnvelopeEncodingError.invalidContent
        }
        try container.encode(senderPubkey, forKey: .senderPubkey)
        try container.encode(senderSig, forKey: .senderSig)
    }
    
    private enum ICPRequestEnvelopeEncodingError: Error {
        case invalidContent
    }
    
    enum CodingKeys: String, CodingKey {
        case content
        case senderPubkey = "sender_pubkey"
        case senderSig = "sender_sig"
    }
}
