//
//  CandidVariant.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 08.05.23.
//

import Foundation

enum CandidVariantError: Error {
    case valueNotPartOfTypes
}

public struct CandidVariant: Equatable {
    public let candidTypes: [CandidDictionaryItemType]
    public let value: CandidValue
    public let valueIndex: UInt
    public var hashedKey: Int { candidTypes[Int(valueIndex)].hashedKey }
    
    public init(candidTypes: [CandidDictionaryItemType], value: CandidValue, valueIndex: UInt) {
        self.candidTypes = candidTypes
        self.value = value
        self.valueIndex = valueIndex
    }
    
    public init(candidTypes: [(String, CandidType)], value: (String, CandidValue)) throws {
        guard let index = candidTypes.firstIndex(where: { $0.0 == value.0 }) else {
            throw CandidVariantError.valueNotPartOfTypes
        }
        self.valueIndex = UInt(index)
        self.candidTypes = candidTypes.map(CandidDictionaryItemType.init)
        self.value = value.1
    }
    
    public subscript (_ key: String) -> CandidValue? {
        self[CandidDictionary.hash(key)]
    }
    
    public subscript (_ key: Int) -> CandidValue? {
        guard hashedKey == key else { return nil }
        return value
    }
}

