//
//  Chia+Array.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Array where Element == ChiaCondition {
    func toSolution() throws -> Data {
        let conditions = ClvmProgram.from(list: self.map { $0.toProgram() })
        let solutionArguments = ClvmProgram.from(list: [conditions]) // might be more than one for other puzzles

        return try solutionArguments.serialize()
    }
}
