//
//  RavencoinTransactionsResponse.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 16.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinTransactionsResponse: Codable {
	let pagesTotal: Int?
	let txs: [TXS]
}

struct TXS: Codable {
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
    let valueOut : Double?
    let size : Int?
    let valueIn : Double?
    let fees : Double?
}

struct Vin : Codable {
    let txid : String?
    let vout : Int?
    let sequence : Int?
    let n : Int?
    let scriptSig : ScriptSig?
    let addr : String?
    let valueSat : Int?
    let value : Double?
    let doubleSpentTxID : String?
}

struct Vout : Codable {
    let value : String?
    let n : Int?
    let scriptPubKey : ScriptPubKey?
    let spentTxId : String?
    let spentIndex : String?
    let spentHeight : String?
}

struct ScriptSig : Codable {
    let hex : String?
    let asm : String?
}

struct ScriptPubKey : Codable {
    let hex : String?
    let asm : String?
    let addresses : [String]?
    let type : String?
}
