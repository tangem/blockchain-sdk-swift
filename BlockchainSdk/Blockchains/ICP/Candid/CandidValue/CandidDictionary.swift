//
//  CandidDictionary.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 27.04.23.
//

import Foundation

public struct CandidDictionary: ExpressibleByDictionaryLiteral, Equatable {
    public let candidSortedItems: [CandidDictionaryItem]
    
    public var candidValues: [CandidValue] {
        candidSortedItems.map { $0.value }
    }
    
    public var candidTypes: [CandidDictionaryItemType] {
        candidSortedItems.map(CandidDictionaryItemType.init)
    }
    
    public init(_ dictionary: [String: CandidValue]) {
        candidSortedItems = dictionary
            .map(CandidDictionaryItem.init)
            .sorted { $0.hashedKey < $1.hashedKey }  // sort by ascending keys
    }
    
    public init(_ hashedDictionary: [Int: CandidValue]) {
        candidSortedItems = hashedDictionary
            .map(CandidDictionaryItem.init)
            .sorted { $0.hashedKey < $1.hashedKey }  // sort by ascending keys
    }
    
    public init(dictionaryLiteral elements: (String, CandidValue)...) {
        let dictionary = Dictionary(uniqueKeysWithValues: elements)
        self.init(dictionary)
    }
    
    public subscript (_ hashedKey: Int) -> CandidValue? {
        candidSortedItems.first { $0.hashedKey == hashedKey }?.value
    }
    
    public subscript (_ key: String) -> CandidValue? {
        let hashedKey = CandidDictionary.hash(key)
        return self[hashedKey]
    }
}

public extension CandidDictionary {
    /// https://github.com/dfinity/candid/blob/master/spec/Candid.md
    /// hash(id) = ( Sum(i=0..k) utf8(id)[i] * 223^(k-i) ) mod 2^32 where k = |utf8(id)|-1
    static func hash(_ key: String) -> Int {
        let data = Data(key.utf8)
        return data.reduce(0) { ($0 * 223 + Int($1)) & 0x00000000ffffffff }
    }
}

public struct CandidDictionaryItem: Equatable {
    public let hashedKey: Int
    public let value: CandidValue
    
    public init(_ hashedKey: Int, _ value: CandidValue) {
        self.hashedKey = hashedKey
        self.value = value
    }
    
    public init(_ key: String, _ value: CandidValue) {
        self.init(CandidDictionary.hash(key), value)
    }
}

public struct CandidDictionaryItemType: Equatable {
    public let hashedKey: Int
    public let type: CandidType
    
    public init(hashedKey: Int, type: CandidType) {
        self.hashedKey = hashedKey
        self.type = type
    }
    
    public init(_ item: CandidDictionaryItem) {
        self.init(hashedKey: item.hashedKey, type: item.value.candidType)
    }
    
    public init(_ key: String, _ type: CandidType) {
        self.hashedKey = CandidDictionary.hash(key)
        self.type = type
    }
}


