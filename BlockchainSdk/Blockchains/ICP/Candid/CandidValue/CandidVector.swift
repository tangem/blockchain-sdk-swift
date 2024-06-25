//
//  CandidVector.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 02.05.23.
//

import Foundation

public struct CandidVector: ExpressibleByArrayLiteral, Equatable {
    private enum CandidVectorError: Error {
        case noElementsAndNoType
        case wrongCandidType
    }
    
    public let values: [CandidValue]
    public let containedType: CandidType
    
    public init(arrayLiteral elements: CandidValue...) {
        try! self.init(Array(elements))
    }
    
    public init(_ containedType: CandidType) {
        self.containedType = containedType
        self.values = []
    }
    
    public init(_ containedType: CandidPrimitiveType) {
        self.init(.primitive(containedType))
    }
    
    public init(_ sequence: any Sequence<CandidValue>) throws {
        guard let type = sequence.first(where: { _ in true })?.candidType else {
            throw CandidVectorError.noElementsAndNoType
        }
        try self.init(type, sequence)
    }
    
    public init(_ type: CandidType, _ sequence: any Sequence<CandidValue>) throws {
        guard sequence.allSatisfy({ $0.candidType == type }) else {
            throw CandidVectorError.wrongCandidType
        }
        values = Array(sequence)
        self.containedType = type
    }
}
