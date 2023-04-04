//
//  RavencoinTransactionInfo.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 03.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinTransactionInfo : Codable {
    let txid : String?
    let version : Int?
    let locktime : Int?
    let vin : [Vin]?
    let vout : [Vout]?
    let blockhash : String?
    let blockheight : Int?
    let confirmations : Int?
    let time : Int?
    let blocktime : Int?
    let valueIn : Double?
    let valueOut : Double?
    let isCoinBase: Bool?
    let size : Int?
    let fees : Double?
}

extension RavencoinTransactionInfo {
    struct ScriptPubKey: Codable {
        let hex : String?
        let asm : String?
        let addresses : [String]?
        let type : String?
    }
    
    struct Vin : Codable {
        let txid : String?
        let vout : Int?
        let sequence : Int?
        let n : Int?
        let scriptSig : ScriptPubKey?
        let addr : String?
        let valueSat : Int?
        let value : Double?
        let doubleSpentTxID : String?
        let coinbase: String?
    }
    
    struct Vout : Codable {
        let value: String?
        let n: Int?
        let scriptPubKey : ScriptPubKey?
        let spentTxId: String?
        let spentIndex: Int?
        let spentHeight: Int?
    }
}

