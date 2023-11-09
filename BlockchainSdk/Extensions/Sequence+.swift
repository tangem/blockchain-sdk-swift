//
//  Sequence+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Sequence where Element: Hashable {
    /// Just a shim for `Set(_:)`.
    func toSet() -> Set<Element> {
        return Set(self)
    }
}
