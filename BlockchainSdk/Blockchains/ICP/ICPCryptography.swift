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
        
        public static func encodeSigned(_ bigInt: BigInt) -> Data {
            // TODO: Make this work with BigInts
            // the BigInt shift operator >> does not produce the same results as the int shift operator...
            // eg.    Int(-129) >> 7 = -2
            //     BigInt(-129) >> 7 = -1   // should be -2
            // shift operator on BigInt is not applied on the 2's complement for negative numbers, instead it is applied on their absolute value.
            assert(bigInt.magnitude < Int.max, "Can not leb128 encode bigInts > Int.max! shift operator not working")
            guard !bigInt.isZero else { return encodeSigned(Int(0)) }
            let integerValue = Int(truncatingIfNeeded: bigInt)
            return encodeSigned(integerValue)
        }
        
        public static func encodeSigned(_ integer: Int) -> Data {
            var value = integer
            var more = true
            var bytes = Data()
            
            while more {
                var byte = UInt8(value & 0x7F)
                value = value >> 7
                if (value == 0 && (byte >> 6) == 0) || (value == -1 && (byte >> 6) == 1) {
                    more = false
                } else {
                    byte |= 0x80
                }
                
                bytes.append(byte)
            }
            return bytes
        }
        
        // MARK: Decoding
        internal static func decodeUnsigned<T: BinaryInteger>(_ stream: ByteInputStream) throws -> T {
            var result: T = .zero
            var shift = 0
            var uint8: UInt8
            repeat {
                uint8 = try stream.readNextByte()
                result = result | (T((0x7F & uint8)) << shift)
                shift += 7
            } while uint8 & 0x80 != 0
            return result
        }
        
        internal static func decodeSigned<T: BinaryInteger>(_ stream: ByteInputStream) throws -> T {
            var result: T = .zero
            var shift = 0
            var uint8: UInt8
            repeat {
                uint8 = try stream.readNextByte()
                result = result | (T((0x7F & uint8)) << shift)
                shift += 7
            } while uint8 & 0x80 != 0
            
            if uint8 & 0x40 != 0 {
                result = result | (~T.zero << shift)
            }
            
            return result
        }
        
        static func decodeUnsigned<T: BinaryInteger>(_ data: Data) throws -> T {
            let stream = ByteInputStream(data)
            return try decodeUnsigned(stream)
        }
        
        static func decodeSigned<T: BinaryInteger>(_ data: Data) throws -> T {
            let stream = ByteInputStream(data)
            return try decodeSigned(stream)
        }
    }
}

extension ICPCryptography {
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
