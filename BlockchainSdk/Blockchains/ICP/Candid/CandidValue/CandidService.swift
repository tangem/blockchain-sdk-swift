//
//  CandidService.swift
//  Runner
//
//  Created by Konstantinos Gaitanis on 15.05.23.
//

import Foundation

struct CandidService: Equatable {
    let methods: [Method]
    let principalId: Data?
    
    struct Method: Equatable {
        let name: String
        let functionSignature: CandidFunctionSignature
    }
}
