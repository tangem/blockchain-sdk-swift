//
//  ICPCryptography.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 21.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift

enum ICPError: Error {
    case invalidChecksum
    case invalidSubAccountId
}

enum ICPCryptography {
    private static let canonicalTextSeparator: String = "-"
    private static let domain: ICPDomainSeparator = "account-id"
    
    static func accountId(of principal: ICPPrincipal, subAccountId: Data) throws -> Data {
        guard subAccountId.count == 32 else {
            throw ICPError.invalidSubAccountId
        }
        let data = Self.domain.data +
                   principal.bytes +
                   subAccountId.bytes
        
        let hashed = data.sha224()
        let checksum = hashed.crc32()
        let accountId = checksum + hashed
        return accountId
    }
    
    static func encodeCanonicalText(_ data: Data) -> String {
        let checksum = data.crc32()
        let dataWithChecksum = checksum + data
        let base32Encoded = dataWithChecksum.base32EncodedString.lowercased().filter { $0 != "=" }
        let grouped = base32Encoded.grouped(by: canonicalTextSeparator, every: 5)
        return grouped
    }
    
    static func decodeCanonicalText(_ text: String) throws -> Data {
        let degrouped = text.replacingOccurrences(of: canonicalTextSeparator, with: "")
        let base32Encoded: String
        if degrouped.count % 2 != 0 { base32Encoded = degrouped + "=" }
        else { base32Encoded = degrouped }
        let decoded = base32Encoded.base32DecodedData!
        
        let crc32Length = 4
        let checksum = decoded.prefix(crc32Length)
        let data = decoded.suffix(from: crc32Length)
        let expectedChecksum = data.crc32()
        guard expectedChecksum == checksum else {
            throw ICPError.invalidChecksum
        }
        return data
    }
}

extension ICPCryptography {
    enum Leb128 {
        public static func encodeUnsigned(_ literal: IntegerLiteralType) -> Data {
            return encodeUnsigned(BigUInt(literal))
        }
        
        public static func encodeUnsigned(_ int: UInt) -> Data {
            return encodeUnsigned(BigUInt(int))
        }
        
        public static func encodeUnsigned(_ bigInt: BigUInt) -> Data {
            var value = bigInt
            var bytes = Data()
            
            repeat {
                var byte = UInt8(value & 0x7F)
                value = value >> 7
                if value != 0 {
                    byte |= 0x80
                }
                bytes.append(byte)
            } while value != 0
            
            return bytes
        }
    }
}

extension ICPCryptography {
    static func selfAuthenticatingPrincipal(uncompressedPublicKey publicKey: Data) throws -> ICPPrincipal {
        let serialized = try Cryptography.der(uncompressedEcPublicKey: publicKey)
        let hash = Cryptography.sha224(serialized)
        let bytes = hash + Data([0x02])
        return ICPPrincipal(bytes)
    }
}

private extension Collection {
    func unfoldSubSequences(limitedTo maxLength: Int) -> UnfoldSequence<SubSequence,Index> {
        sequence(state: startIndex) { start in
            guard start < endIndex else { return nil }
            let end = index(start, offsetBy: maxLength, limitedBy: endIndex) ?? endIndex
            defer { start = end }
            return self[start..<end]
        }
    }
}

private extension StringProtocol where Self: RangeReplaceableCollection {
    func grouped(by separator: any StringProtocol, every groupLength: Int) -> String {
        return String(unfoldSubSequences(limitedTo: groupLength).joined(separator: separator))
    }
}
