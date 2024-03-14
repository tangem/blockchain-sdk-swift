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
    let value: Decimal
    let height: Decimal
}

public struct ElectrumResponse {
    let balance: Decimal
    let outputs: [ElectrumUTXO]
}

public class ElectrumNetworkProvider: MultiNetworkProvider {
    let providers: [ElectrumWebSocketManager]
    var currentProviderIndex: Int = 0
    
    private let decimalValue: Decimal
    
    public init(providers: [ElectrumWebSocketManager], decimalValue: Decimal) {
        self.providers = providers
        self.decimalValue = decimalValue
        
        print("init ElectrumNetworkProvider")
    }
    
    deinit {
        print("deinit ElectrumNetworkProvider")
    }
    
    public func getAddressInfo(address: String) -> AnyPublisher<ElectrumResponse, Error> {
        providerPublisher { provider in
                .init {
                    async let balance = provider.getBalance(address: address)
//                    async let unspents = provider.getTxHistory(address: address)
                    
                    return try await ElectrumResponse(
                        balance: Decimal(balance.confirmed),
                        outputs: []
//                        unspents.map { unspent in
//                            ElectrumUTXO(
//                                position: unspent.txPos,
//                                hash: unspent.txHash,
//                                value: unspent.value,
//                                height: unspent.height
//                            )
//                        }
                    )
                }
        }
    }
    
    public func estimateFee() -> AnyPublisher<Decimal, Error> {
        providerPublisher { provider in
                .init {
                    let fee = try await provider.estimateFee(block: 10)
                    return Decimal(fee)
                }
        }
    }
}

extension AnyPublisher where Failure: Error {
    struct Subscriber {
        private let send: (Output) -> Void
        private let complete: (Subscribers.Completion<Failure>) -> Void
        
        init(
            send: @escaping (Output) -> Void,
            complete: @escaping (Subscribers.Completion<Failure>) -> Void
        ) {
            self.send = send
            self.complete = complete
        }

        func send(_ value: Output) { send(value) }
        func send(completion: Subscribers.Completion<Failure>) { complete(completion) }
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
