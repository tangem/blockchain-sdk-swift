//
//  OrderIndependentHash.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 27.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import PotentCodables
import BigInt
import CryptoKit

extension ICPCryptography {
    /// https://internetcomputer.org/docs/current/references/ic-interface-spec/#hash-of-map
    static func orderIndependentHash(_ value: any Encodable) throws -> Data {
        return try OIHasher { data in
            Data(CryptoKit.SHA256.hash(data: data).bytes)
        }.encode(value)
    }
}

private struct OIHasher: PotentCodables.EncodesToData {
    private let hashFunction: (any DataProtocol) -> Data
    
    init(_ hashFunction: @escaping (any DataProtocol) -> Data) {
        self.hashFunction = hashFunction
    }
    
    enum OIHasherError: Error {
        case unsupportedDataType(AnyValue)
        case nonUtf8String(String)
        case nonPositiveNumber(BigInt)
        case nonAsciiString(AnyValue)
    }
    typealias Value = AnyValue
    func encodeTree<T: Encodable>(_ value: T) throws -> AnyValue {
        try AnyValueEncoder.default.encodeTree(value)
    }
    
    func encode<T: Encodable>(_ value: T) throws -> Data {
        let tree = try encodeTree(value)
        return try hash(tree)
    }
    
    private func hash(_ value: AnyValue) throws -> Data {
        let dataToHash: Data
        switch value {
        case .string(let string): dataToHash = try encode(string)
        case .uint8(let uint8): dataToHash = encode(uint8)
        case .uint16(let uint16): dataToHash = encode(uint16)
        case .uint32(let uint32): dataToHash = encode(uint32)
        case .uint64(let uint64): dataToHash = encode(uint64)
        case .int8(let int8): dataToHash = try encode(int8)
        case .int16(let int16): dataToHash = try encode(int16)
        case .int32(let int32): dataToHash = try encode(int32)
        case .int64(let int64): dataToHash = try encode(int64)
        case .integer(let bigInt): dataToHash = try encode(bigInt)
        case .data(let data): dataToHash = data
            
        case .array(let array):
            dataToHash = try array
                .map { try hash($0) }
                .reduce(Data(), +)
            
        case .dictionary(let dictionary):
            dataToHash = try dictionary
                .map { (key, value) in
                    let keyAscii = try encodeAscii(key)
                    let keyHash = hashFunction(keyAscii)
                    let valueHash = try hash(value)
                    return keyHash + valueHash
                }
                .sorted()
                .reduce(Data(), +)
            
        default:
            throw OIHasherError.unsupportedDataType(value)
        }
        
        let hashed = hashFunction(dataToHash)
        return hashed
    }
    
    private func encode(_ string: String) throws -> Data {
        guard let utf8data = string.data(using: .utf8) else {
            throw OIHasherError.nonUtf8String(string)
        }
        return utf8data
    }
    
    private func encodeAscii(_ string: AnyValue) throws -> Data {
        guard let keyAscii = string.stringValue?.data(using: .ascii) else {
            throw OIHasherError.nonAsciiString(string)
        }
        return keyAscii
    }
    
    private func encode(_ integer: any UnsignedInteger) -> Data {
        return ICPCryptography.Leb128.encodeUnsigned(BigUInt(integer))
    }
    
    private func encode(_ integer: any SignedInteger) throws -> Data {
        let bigInt = BigInt(integer)
        guard bigInt.sign == .plus else {
            throw OIHasherError.nonPositiveNumber(bigInt)
        }
        return ICPCryptography.Leb128.encodeUnsigned(bigInt.magnitude)
    }
    
    
}

extension Data: Comparable {
    public static func < (lhs: Data, rhs: Data) -> Bool {
        guard lhs.count == rhs.count else {
            return lhs.count < rhs.count
        }
        if lhs.isEmpty && rhs.isEmpty { return false }
        if lhs.isEmpty { return true }
        if rhs.isEmpty { return false }
        return lhs.first! < rhs.first!
    }
}
