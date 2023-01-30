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
    
    
    /// Parse address form in User-Friendly address
    /// - Parameter addressString: Any form address of wallet
    /// - Returns: TONAddress form {isTestOnly: boolean, workchain: number, hashPart: Uint8Array, isBounceable: boolean}
    static func parseFriendlyAddress(_ addressString: String) throws -> TONAddress {
        guard addressString.count == 48 else {
            throw TONError.exception("User-friendly address should contain strictly 48 characters")
        }
        
        guard
            let data = Data(base64EncodedURLSafe: addressString),
            data.count == 36
        else {
            throw TONError.exception("Unknown address type: byte length is not equal to 36")
        }
        
        let addrData = Array(data.bytes[0..<34])
        let crcData = Array(data.bytes[34..<36])
        let calcedCrc = crc16(data: addrData).bigEndian.data.bytes

        if (!(calcedCrc[0] == crcData[0] && calcedCrc[1] == crcData[1])) {
            throw TONError.exception("Wrong crc16 hashsum")
        }

        var tag = addrData[0]
        var isTestOnly = false
        var isBounceable = false
        
        if ((tag & TONAddressTag.TEST_ONLY.rawValue) != 0) {
            isTestOnly = true
            tag = tag ^ TONAddressTag.TEST_ONLY.rawValue
        }
        
        if tag != TONAddressTag.BOUNCEABLE.rawValue, tag != TONAddressTag.NON_BOUNCEABLE.rawValue {
            throw TONError.exception("Unknown address tag")
        }

        isBounceable = tag == TONAddressTag.BOUNCEABLE.rawValue

        var workchain: Int = 0
        
        workchain = addrData[1] == 0xff ? -1 : Int(addrData[1])
        
        if workchain != 0, workchain != -1 {
            throw TONError.exception("Invalid address wc")
        }

        let hashPart = Data(Array(addrData[2..<34]))

        return TONAddress(
            isTestOnly: isTestOnly,
            isBounceable: isBounceable,
            workchain: workchain,
            hashPart: hashPart
        )
    }
    
    // MARK: - Properties
    
    var wc: Int
    var hashPart: Data
    var isTestOnly: Bool
    var isUserFriendly: Bool
    var isBounceable: Bool
    var isUrlSafe: Bool
    
    // MARK: - Init
               
    init (
        isTestOnly: Bool,
        isUserFriendly: Bool = false,
        isBounceable: Bool,
        workchain: Int,
        hashPart: Data,
        isUrlSafe: Bool = true
    ) {
        self.wc = workchain
        self.hashPart = hashPart
        self.isTestOnly = isTestOnly
        self.isUserFriendly = false
        self.isBounceable = isBounceable
        self.isUrlSafe = isUrlSafe
    }
    
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
            self.isUserFriendly = true
            let parseResult = try TONAddress.parseFriendlyAddress(anyForm)
            self.wc = parseResult.wc
            self.hashPart = parseResult.hashPart
            self.isTestOnly = parseResult.isTestOnly
            self.isBounceable = parseResult.isBounceable
            self.isUrlSafe = parseResult.isUrlSafe
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
            var tag: UInt8 = isBounceable ? TONAddressTag.BOUNCEABLE.rawValue : TONAddressTag.NON_BOUNCEABLE.rawValue
            
            if (isTestOnly) {
                tag |= TONAddressTag.TEST_ONLY.rawValue
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
