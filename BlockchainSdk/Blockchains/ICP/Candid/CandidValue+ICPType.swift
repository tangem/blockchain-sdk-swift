//
//  CandidValue+ICPType.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension CandidValue {
    var ICPAmount: UInt64? { recordValue?["e8s"]?.natural64Value }
    var ICPTimestamp: UInt64? {
        guard let nanos = recordValue?["timestamp_nanos"]?.natural64Value else { return nil }
        return nanos
    }
    
    static func ICPAmount(_ amount: UInt64) -> CandidValue {
        .record(["e8s": .natural64(amount)])
    }
    
    static func ICPTimestamp(_ timestamp: UInt64) -> CandidValue {
        return .record([
            "timestamp_nanos": .natural64(timestamp)
        ])
    }
    
    static func ICPTimestampNow() -> CandidValue {
        return ICPTimestamp(UInt64(Date().timeIntervalSince1970) * 1_000_000_000)
    }
}
