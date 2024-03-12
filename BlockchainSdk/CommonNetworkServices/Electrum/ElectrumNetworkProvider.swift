//
//  ElectrumNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

public struct ElectrumUTXO {
    let position: Int
    let hash: String
    let value: Int
    let height: String
}

public class ElectrumNetworkProvider: MultiNetworkProvider {
    let providers: [ElectrumWebSocketManager]
    var currentProviderIndex: Int = 0
    
    private let decimalValue: Decimal
    
    public init(providers: [ElectrumWebSocketManager], decimalValue: Decimal) {
        self.providers = providers
        self.decimalValue = decimalValue
    }
    
    public func getBalance(address: String) -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
                .init {
                    let balance = try await provider.getBalance(address: address)
                    return Decimal(balance.confirmed) / self.decimalValue
                }
        }
    }
    
    public func getUnspents(address: String) -> AnyPublisher<[ElectrumUTXO], Error> {
        providerPublisher { provider in
                .init {
                    let unspents = try await provider.getUnspents(address: address)
                    return unspents.map { unspent in
                        ElectrumUTXO(
                            position: unspent.txPos,
                            hash: unspent.txHash,
                            value: unspent.value,
                            height: unspent.height
                        )
                    }
                }
        }
    }
}

extension AnyPublisher where Failure: Error {
    struct Subscriber {
        fileprivate let send: (Output) -> Void
        fileprivate let complete: (Subscribers.Completion<Failure>) -> Void

        func send(_ value: Output) { self.send(value) }
        func send(completion: Subscribers.Completion<Failure>) { self.complete(completion) }
    }

    init(_ closure: (Subscriber) -> AnyCancellable) {
        let subject = PassthroughSubject<Output, Failure>()

        let subscriber = Subscriber(
            send: subject.send,
            complete: subject.send(completion:)
        )
        let cancel = closure(subscriber)

        self = subject
            .handleEvents(receiveCancel: cancel.cancel)
            .eraseToAnyPublisher()
    }
}


extension AnyPublisher where Failure == Error {
    init(taskPriority: TaskPriority? = nil, asyncFunc: @escaping () async throws -> Output) {
        self.init { subscriber in
            let task = Task(priority: taskPriority) {
                do {
                    subscriber.send(try await asyncFunc())
                    subscriber.send(completion: .finished)
                } catch {
                    subscriber.send(completion: .failure(error))
                }
            }
            return AnyCancellable { task.cancel() }
        }
    }
}
