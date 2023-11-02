//
//  AnyPublisher+.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 12/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Combine

// TODO: Andrey Fedorov - These extensions aren't made for `AnyPublisher`, move them to the correct location and fix visibility (IOS-4990)
@available(iOS 13.0, *)
public extension Publisher {
    static func anyFail(error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error)
            .eraseToAnyPublisher()
    }
    
    static var emptyFail: AnyPublisher<Output, Error> {
        Fail(error: WalletError.empty)
            .eraseToAnyPublisher()
    }
    
    static func justWithError(output: Output) -> AnyPublisher<Output, Error> {
        Just(output)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    static func multiAddressPublisher<T>(addresses: [String], requestFactory: (String) -> AnyPublisher<T, Error>) -> AnyPublisher<[T], Error> {
        Publishers.MergeMany(addresses.map {
            requestFactory($0)
        })
        .collect()
        .eraseToAnyPublisher()
    }
}
