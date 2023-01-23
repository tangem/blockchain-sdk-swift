//
//  TONAddress.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 18.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import Foundation

public struct TONAddress {
    
    /// Validate TON Address
    /// - Parameter anyForm: Форма адреса в формате строки
    static func isValid(anyForm: String) -> Bool {
        guard
            anyForm.count == 48,
            let rawData = Data(base64EncodedURLSafe: anyForm),
            rawData.count == 36
        else {
            return false
        }
        
        let addrData = rawData[0...33]
        let crcData = rawData[34...35]
        let calcedCrc = crc16(data: addrData.bytes).bigEndian.data.bytes
        
        if (!(calcedCrc[0] == crcData.bytes[0] && calcedCrc[1] == crcData.bytes[1])) {
            return false
        }
        
        return true
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
    let isUrlSafe: Bool
    
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
        if anyForm.index(of: ":") != nil {
            let arr = anyForm.components(separatedBy: ":")
            
            guard arr.count == 2 else {
                throw NSError()
            }
            
            let hexPath = arr[1]
            
            guard let wc = Int(arr[0]), (wc == 0 || wc == -1), hexPath.count == 64 else {
                throw NSError()
            }
            
            self.wc = wc
            self.hashPart = Data(hex: hexPath)
            self.isTestOnly = false
            self.isUserFriendly = false
            self.isBounceable = false
            self.isUrlSafe = false
        } else {
            throw NSError()
        }
    }
    
    // MARK: - Implementation
    
    /// Вывод адреса формате строки
    /// - Parameters:
    ///   - isUserFriendly: Формат удобной представления пользователя
    ///   - isUrlSafe: Представление в формате safeUrl
    ///   - isBounceable: Возвращаемый тип транзакции
    ///   - isTestOnly: Только для тестирования
    /// - Returns: Base64Url string
    public func toString(
        isUserFriendly: Bool? = nil,
        isUrlSafe: Bool? = nil,
        isBounceable: Bool? = nil,
        isTestOnly: Bool? = nil
    ) -> String {
        let isUserFriendly: Bool = isUserFriendly == nil ? self.isUserFriendly : isUserFriendly!
        let isUrlSafe: Bool = isUrlSafe == nil ? self.isUrlSafe : isUrlSafe!
        let isBounceable: Bool = isBounceable == nil ? self.isBounceable : isBounceable!
        let isTestOnly: Bool = isTestOnly == nil ? self.isTestOnly : isTestOnly!

        if !isUserFriendly {
            return "\(wc):\(hashPart.hexString)"
        } else {
            var tag: UInt8 = isBounceable ? AddressTag.BOUNCEABLE.rawValue : AddressTag.NON_BOUNCEABLE.rawValue
            
            if (isTestOnly) {
                tag |= AddressTag.TEST_ONLY.rawValue
            }

            var addr = [UInt8]()
            addr.append(tag)
            addr.append(UInt8(wc))
            addr.append(contentsOf: hashPart.bytes)

            var addressWithChecksum = [UInt8]()
            addressWithChecksum.append(contentsOf: addr)
            addressWithChecksum.append(contentsOf: crc16(data: addr).bigEndian.data.bytes)

            if (isUrlSafe) {
                return Data(addressWithChecksum).base64EncodedURLSafe()
            } else {
                return Data(addressWithChecksum).base64EncodedString()
            }
        }
    }
    
}

private func crc16(data: [UInt8]) -> UInt16 {
    // Calculate checksum for existing bytes
    var crc: UInt16 = 0x0000;
    let polynomial: UInt16 = 0x1021;
    
    for byte in data {
        for bitidx in 0..<8 {
            let bit = ((byte >> (7 - bitidx) & 1) == 1)
            let c15 = ((crc >> 15 & 1) == 1)
            crc <<= 1
            if c15 ^ bit {
                crc ^= polynomial;
            }
        }
    }
    
    return crc & 0xffff;
}
