//
//  CandidFunction.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 15.05.23.
//

import Foundation

public struct CandidFunction: Equatable {
    public let signature: CandidFunctionSignature
    public let method: ServiceMethod?
    
    public struct ServiceMethod: Equatable {
        public let name: String
        public let principalId: Data
    }
}

public struct CandidFunctionSignature: Equatable {
    public let inputs: [CandidType]
    public let outputs: [CandidType]
    
    /// indicates that the referenced function is a query method,
    /// meaning it does not alter the state of its canister, and that
    /// it can be invoked using the cheaper “query call” mechanism.
    public let isQuery: Bool
    /// indicates that this function returns no response, intended for fire-and-forget scenarios.
    public let isOneWay: Bool
}
