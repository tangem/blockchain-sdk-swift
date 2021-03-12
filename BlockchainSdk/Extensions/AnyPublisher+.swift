//
//  AnyPublisher+.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine

extension AnyPublisher {
    static func anyFail(error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error)
            .eraseToAnyPublisher()
    }
    
    static var emptyFail: AnyPublisher<Output, Error> {
        Fail(error: "")
            .eraseToAnyPublisher()
    }
}
