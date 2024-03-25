//
//  PolkadotAccountHealthChecker.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import BackgroundTasks

final class PolkaDotAccountHealthChecker {
    // TODO: Andrey Fedorov - Protect access to all storage properties
//    @AppStorageCompat(StorageKeys.currentlyAnalyzedAccounts)
    private var currentlyAnalyzedAccounts: [String] = []

//    @AppStorageCompat(StorageKeys.fullyAnalyzedAccounts)
    private var fullyAnalyzedAccounts: [String] = []

//    @AppStorageCompat(StorageKeys.analyzedForResetAccounts)
    private var analyzedForResetAccounts: [String] = []

//    @AppStorageCompat(StorageKeys.analyzedForImmortalTransactionsAccounts)
    private var analyzedForImmortalTransactionsAccounts: [String] = []

//    @AppStorageCompat(StorageKeys.lastAnalyzedTransactionIds)
    private var lastAnalyzedTransactionIds: [String: Int] = [:]

    private var healthCheckTasks: [String: Task<Void, Never>] = [:]
    private var backgroundHealthCheckTask: Task<Void, Never>?

    private let networkService: PolkadotAccountHealthNetworkService

    private var backgroundTaskIdentifier: String {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]

        guard let bundleIdentifier = infoDictionary["CFBundleIdentifier"] as? String else {
            preconditionFailure("Unable to get app bundle identifier")
        }
        return bundleIdentifier + "." + Constants.backgroundTaskName
    }

    init(networkService: PolkadotAccountHealthNetworkService) {
        self.networkService = networkService

        setup() // TODO: Andrey Fedorov - Perform setup lazily instead
    }

    func analyzeAccountIfNeeded(_ account: String) {
        guard !fullyAnalyzedAccounts.contains(account) else {
            return
        }

        currentlyAnalyzedAccounts.append(account)
        healthCheckTasks[account] = Task { [weak self] in
            await self?.scheduleForegroundHealthCheck(for: account)
        }
    }

    // MARK: - Setup

    private func setup() {
        Task { [weak self] in
            await self?.setupObservers()
        }
        registerBackgroundTask()
        cancelBackgroundHealthCheck() // Cancels all tasks from previous runs
    }

    private func setupObservers() async {
        if #available(iOS 15, *) {
            /*
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                handleApplicationStatusChange(isBackground: true)
            }
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                handleApplicationStatusChange(isBackground: false)
            }
             */
        } else {
            preconditionFailure()
        }
    }

    private func cleanupAll() {
        let accounts = currentlyAnalyzedAccounts
        accounts.forEach(cleanup(account:))
        backgroundHealthCheckTask?.cancel()
    }

    private func cleanup(account: String) {
        healthCheckTasks[account]?.cancel()
        currentlyAnalyzedAccounts.removeAll { $0 == account }
    }

    private func registerBackgroundTask() {
        let result = BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { [weak self] task in
            if let task = task as? BGProcessingTask {
                self?.handleBackgroundProcessingTask(task)
            } else {
                preconditionFailure("Unsupported type of background task '\(type(of: task))' received") // TODO: Andrey Fedorov - Add proper logging
            }
        }
        print(#function, result) // TODO: Andrey Fedorov - Add proper logging
    }

    // MARK: - Foreground health check

    private func scheduleForegroundHealthCheck(for account: String) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask {
                await self.checkAccountForReset(account)
            }
            taskGroup.addTask {
                await self.checkIfAccountContainsImmortalTransactions(account)
            }
        }
        currentlyAnalyzedAccounts.removeAll { $0 == account }
    }

    // MARK: - Background health check

    private func scheduleBackgroundHealthCheck() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.backgroundTaskDelay) // Allows already running foreground checks to finish
        request.requiresNetworkConnectivity = true

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print(error) // TODO: Andrey Fedorov - Catch & log error properly
        }
    }

    private func cancelBackgroundHealthCheck() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
    }

    private func handleBackgroundProcessingTask(_ task: BGProcessingTask) {
        task.expirationHandler = { [weak self] in
            self?.cleanupAll()
        }

        backgroundHealthCheckTask = Task { [weak self] in
            guard let self else {
                return
            }

            let accounts = currentlyAnalyzedAccounts
            await withTaskGroup(of: Void.self) { taskGroup in
                accounts.forEach { account in
                    taskGroup.addTask {
                        await self.scheduleForegroundHealthCheck(for: account)
                    }
                }
            }
        }
    }

    @MainActor
    private func handleApplicationStatusChange(isBackground: Bool) {
        if isBackground {
            scheduleBackgroundHealthCheck()
        } else {
            // TODO: Andrey Fedorov - Restart normal check here
            cancelBackgroundHealthCheck()
        }
    }

    // MARK: - Shared logic

    private func checkAccountForReset(_ account: String) async {
        guard !analyzedForResetAccounts.contains(account) else {
            return
        }

        // TODO: Andrey Fedorov - Add retries (using common helper perhaps?)
        // TODO: Andrey Fedorov - Try to map API error first (using common helper perhaps?)
        do {
            let healthInfo = try await networkService.getAccountHealthInfo(account: account)

            // Double checking is a must since theoretically there can be multiple ongoing checks
            guard !analyzedForResetAccounts.contains(account) else {
                return
            }

            // `accountInfo.nonce` can be equal to or greater than the count of extrinsics,
            // but can't it be less (unless the account has been reset)
            let metric: AccountHealthMetric = .hasBeenReset(value: healthInfo.nonceCount < healthInfo.extrinsicCount)
            await sendAccountHealthMetric(metric)
            analyzedForResetAccounts.append(account)
        } catch {
            print(error) // TODO: Andrey Fedorov - Catch & log error properly
        }
    }

    private func checkIfAccountContainsImmortalTransactions(_ account: String) async {
        // TODO: Andrey Fedorov - Add retries (using common helper perhaps?)
        // TODO: Andrey Fedorov - Try to map API error first (using common helper perhaps?)
        do {
            var foundImmortalTransaction = false

        transactionsListLoop: while true {
            let afterId = lastAnalyzedTransactionIds[account, default: Constants.initialTransactionId]
            let transactions = try await networkService.getTransactionsList(account: account, afterId: afterId)

            // Checking if we've reached the end of the transactions list
            guard !transactions.isEmpty else {
                break transactionsListLoop
            }

            for transaction in transactions {
                let isTransactionImmortal = try await isTransactionImmortal(transaction)
                lastAnalyzedTransactionIds[account] = transaction.id
                // Early exit if we've found at least one immortal transaction
                if isTransactionImmortal {
                    foundImmortalTransaction = true
                    break transactionsListLoop
                }
            }
        }

            // Double checking is a must since theoretically there can be multiple ongoing checks
            guard !analyzedForImmortalTransactionsAccounts.contains(account) else {
                return
            }

            let metric: AccountHealthMetric = .hasImmortalTransaction(value: foundImmortalTransaction)
            await sendAccountHealthMetric(metric)
            analyzedForImmortalTransactionsAccounts.append(account)
        } catch {
            print(error) // TODO: Andrey Fedorov - Catch & log error properly
        }
    }

    private func isTransactionImmortal(_ transaction: PolkadotTransaction) async throws -> Bool {
        // Adding small delays between consecutive fetches of transaction details to avoid hitting the API rate limit
        try await Task.sleep(nanoseconds: UInt64(Constants.transactionInfoCheckDelay) * NSEC_PER_SEC)   // TODO: Andrey Fedorov - Add some random jitter

        let details = try await networkService.getTransactionDetails(hash: transaction.hash)

        return details.birth == nil || details.death == nil
    }

    @MainActor
    private func sendAccountHealthMetric(_ metric: AccountHealthMetric) {
        switch metric {
        case .hasBeenReset(let value):
            break
//            let value: Analytics.ParameterValue = .affirmativeOrNegative(for: value)
//            Analytics.log(event: .healthCheckPolkadotAccountReset, params: [.state: value.rawValue])
        case .hasImmortalTransaction(let value):
            break
//            let value: Analytics.ParameterValue = .affirmativeOrNegative(for: value)
//            Analytics.log(event: .healthCheckPolkadotImmortalTransactions, params: [.state: value.rawValue])
        }
    }
}

// MARK: - Auxiliary types

private extension PolkaDotAccountHealthChecker {
    enum AccountHealthMetric {
        case hasBeenReset(value: Bool)
        case hasImmortalTransaction(value: Bool)
    }
}

// MARK: - Constants

private extension PolkaDotAccountHealthChecker {
    enum StorageKeys: String, RawRepresentable {
        case currentlyAnalyzedAccounts = "polka_dot_account_health_checker_currently_analyzed_accounts"
        case fullyAnalyzedAccounts = "polka_dot_account_health_checker_fully_analyzed_accounts"
        case analyzedForResetAccounts = "polka_dot_account_health_checker_analyzed_for_reset_accounts"
        case analyzedForImmortalTransactionsAccounts = "polka_dot_account_health_checker_analyzed_for_immortal_transactions_accounts"
        case lastAnalyzedTransactionIds = "polka_dot_account_health_checker_last_analyzed_transaction_ids"
    }
}

private extension PolkaDotAccountHealthChecker {
    enum Constants {
        /// - Warning: Must match the value specified in the `Info.plist`.
        static let backgroundTaskName = "PolkaDotAccountHealthCheckTask"
        /// 10 minutes.
        static let backgroundTaskDelay = 60.0 * 10.0
        static let initialTransactionId = 0
        static let transactionInfoCheckDelay = 1.0
    }
}
