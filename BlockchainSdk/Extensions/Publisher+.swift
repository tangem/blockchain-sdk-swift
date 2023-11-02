//
//  Publisher+.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 16.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
extension Publisher {
    func withWeakCaptureOf<Object>(
        _ object: Object
    ) -> Publishers.CompactMap<Self, (Object, Self.Output)> where Object: AnyObject {
        return compactMap { [weak object] output in
            guard let object = object else { return nil }

            return (object, output)
        }
    }
}
