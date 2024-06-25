//
//  CandidOption.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 02.05.23.
//

import Foundation

public enum CandidOption: Equatable {
    case none(CandidType)
    case some(CandidValue)
    
    public var value: CandidValue? {
        guard case .some(let wrapped) = self else { return nil }
        return wrapped
    }
    
    public var containedType: CandidType {
        switch self {
        case .none(let type): return type
        case .some(let value): return value.candidType
        }
    }
}
