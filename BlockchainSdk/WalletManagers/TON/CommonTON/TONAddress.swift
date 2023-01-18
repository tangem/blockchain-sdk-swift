//
//  TONAddress.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct TONAddress {
    
    /// Validate TON Address
    /// - Parameter anyForm: Форма адреса в формате строки
    static func isValid(anyForm: String) -> Bool {
        do {
            let address = try TONAddress(anyForm)
            return true
        } catch {
            return false
        }
    }
    
    /// Validate TON Address
    /// - Parameter anyForm: Форма адреса в формате модели адреса
    static func isValid(anyForm: TONAddress) -> Bool {
        do {
            _ = try TONAddress(anyForm)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Properties
    
    let wc: Int
    let hashPart: Data
    let isTestOnly: Bool
    let isUserFriendly: Bool
    let isBounceable: Bool
    let isUrlSafe: String
    
    // MARK: - Init
    
    init(_ anyForm: TONAddress) throws {
        self.wc = anyForm.wc
        self.hashPart = anyForm.hashPart
        self.isTestOnly = anyForm.isTestOnly
        self.isUserFriendly = anyForm.isUserFriendly
        self.isBounceable = anyForm.isBounceable
        self.isUrlSafe = anyForm.isUrlSafe
    }
    
    init(_ anyForm: String) throws {
        throw NSError()
    }
    
    // MARK: - Implementation
    
    /// Вывод адреса формате строки
    /// - Parameters:
    ///   - isUserFriendly: Формат удобной представления пользователя
    ///   - isUrlSafe: Представление в формате safeUrl
    ///   - isBounceable: Возвращаемый тип транзакции
    ///   - isTestOnly: Только для тестирования
    /// - Returns: Base64Url string
    private func toString(
        isUserFriendly: Bool,
        isUrlSafe: Bool,
        isBounceable: Bool,
        isTestOnly: Bool
    ) -> String {
        return ""
    }
    
}
