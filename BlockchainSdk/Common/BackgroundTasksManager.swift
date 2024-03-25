//
//  BackgroundTasksManager.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 26.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BackgroundTasks

public final class BackgroundTasksManager {
    public static let shared = BackgroundTasksManager(backgroundTasksToRegister: BackgroundTask.allCases)

    private var bundleIdentifier: String!
    private let backgroundTasksToRegister: [BackgroundTask]

    init(backgroundTasksToRegister: [BackgroundTask]) {
        assert(backgroundTasksToRegister.count <= 10, "iOS currently supports maximum 10 background processing tasks")
        self.backgroundTasksToRegister = backgroundTasksToRegister
    }

    public func registerBackgroundTasks(forApplicationWithBundleIdentifier bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier

        for backgroundTask in backgroundTasksToRegister {
            let identifier = makeBackgroundTaskIdentifier(for: backgroundTask)
            let result = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { [weak self] task in
                if let task = task as? BGProcessingTask {
                    self?.handleBackgroundProcessingTask(task)
                } else {
                    preconditionFailure("Unsupported type of background task '\(type(of: task))' received") // TODO: Andrey Fedorov - Add proper logging
                }
            }

            print(#function, result) // TODO: Andrey Fedorov - Add proper logging
        }
    }

    private func handleBackgroundProcessingTask(_ task: BGProcessingTask) {
        // TODO: Andrey Fedorov - Add actual implementation
    }

    private func makeBackgroundTaskIdentifier(for backgroundTask: BackgroundTask) -> String {
        bundleIdentifier + "." + backgroundTask.rawValue
    }
}

// MARK: - Auxiliary types

extension BackgroundTasksManager {
    enum BackgroundTask: String, CaseIterable {
        case polkadotAccountHealthCheck = "PolkaDotAccountHealthCheckTask"
    }
}
