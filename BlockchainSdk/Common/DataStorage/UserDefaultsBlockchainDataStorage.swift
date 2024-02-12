//
//  UserDefaultsBlockchainDataStorage.swift
//  BlockchainSdk
//
//  Created by Andrey Fedorov on 10.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import class TangemSdk.Log

struct UserDefaultsBlockchainDataStorage<T> where T: Codable {
    private let suiteName: String?
    private var userDefaults: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }
}

// MARK: - BlockchainDataStorage protocol conformance

extension UserDefaultsBlockchainDataStorage: BlockchainDataStorage {
    func get(key: String) async -> T? {
        return await Task {
            guard let data = userDefaults.data(forKey: key) else {
                return nil
            }

            guard let value = try? JSONDecoder().decode(T.self, from: data) else {
                Log.warning("\(#fileID): Unable to deserialize stored value for key '\(key)'")
                return nil
            }

            return value
        }.value
    }

    func store(key: String, value: T?) async {
        Task {
            guard let value else {
                // Removing existing stored data for a given key if a `nil` value is received
                userDefaults.removeObject(forKey: key)
                return
            }

            guard let data = try? JSONEncoder().encode(value) else {
                Log.warning("\(#fileID): Unable to serialize given value of type '\(T.self)' for key '\(key)'")
                return
            }

            userDefaults.setValue(data, forKey: key)
        }
    }
}
