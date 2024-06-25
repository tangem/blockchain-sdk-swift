//
//  CandidValue+Init.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 02.05.23.
//

import Foundation

extension CandidValue {
    static func option(_ value: CandidValue) -> CandidValue {
        return .option(.some(value))
    }
    
    static func option(_ containedType: CandidType) -> CandidValue {
        return .option(.none(containedType))
    }
    
    static func option(_ containedType: CandidPrimitiveType) -> CandidValue {
        return .option(.primitive(containedType))
    }
    
    static func option(_ containedType: CandidType, _ value: CandidValue?) -> CandidValue {
        guard let value = value else {
            return .option(containedType)
        }
        return .option(value)
    }
    
    static func vector(_ containedType: CandidType) -> CandidValue {
        return .vector(CandidVector(containedType))
    }
    
    static func vector(_ containedType: CandidPrimitiveType) -> CandidValue {
        return .vector(CandidVector(containedType))
    }
}
