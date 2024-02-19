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

extension Publisher where Failure == Swift.Error {
    func asyncMap<T>(
        priority: TaskPriority? = nil,
        _ transform: @escaping (_ input: Self.Output) async throws -> T
    ) -> some Publisher<T, Self.Failure> {
        return Publishers.AsyncMap(upstream: self, priority: priority, transform: transform)
    }
}

// MARK: - Private implementation

private extension Publishers {
    struct AsyncMap<Upstream, Output>: Publisher where Upstream: Publisher, Upstream.Failure == Swift.Error {
        typealias Output = Output
        typealias Failure = Upstream.Failure
        typealias Transform = (_ input: Upstream.Output) async throws -> Output

        let upstream: Upstream
        let priority: TaskPriority?
        let transform: Transform

        init(upstream: Upstream, priority: TaskPriority?, transform: @escaping Transform) {
            self.upstream = upstream
            self.priority = priority
            self.transform = transform
        }

        func receive<S>(subscriber: S) where S: Subscriber, Upstream.Failure == S.Failure, Self.Output == S.Input {
            upstream
                .flatMap { output in
                    let subject = PassthroughSubject<Output, Failure>()

                    let task = Task(priority: priority) {
                        do {
                            let mapped = try await transform(output)
                            subject.send(mapped)
                            subject.send(completion: .finished)
                        } catch {
                            subject.send(completion: .failure(error))
                        }
                    }

                    return subject.handleEvents(receiveCancel: task.cancel)
                }
                .receive(subscriber: subscriber)
        }
    }
}
