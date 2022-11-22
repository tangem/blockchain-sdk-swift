//
//  BTCGetBlockResponses.swift
//  BlockchainSdk
//
//  Created by Pavel Grechikhin on 20.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinGetBlockSendResponse: Decodable {
    let txid: String
    let hash: String
    let version: Int
    let size: Int
    let vsize: Int
    let weight: Int
    let locktime: Int
    let vin: [Vin]
    let vout: [Vout]
    let hex: String
    
    struct Vin: Decodable {
        let txid: String
        let vout: Int
        let scriptSig: ScriptSig
        let sequence: Int
    }
    
    struct ScriptSig: Decodable {
        let asm: String
        let hex: String
    }
    
    struct Vout: Decodable {
        let value: Double
        let n: Int
        let scriptPubKey: ScriptPubKey
    }
    
    struct ScriptPubKey: Decodable {
        let asm: String
        let hex: String
        let reqSigs: Int
        let type: String
        let addresses: [String]
    }
}

struct BitcoinGetBlockFeeResponse: Codable {
    let result: Result
    let error: String?
    let id: String
    
    struct Result: Codable {
        let feerate: Double
        let blocks: Int
    }
}
