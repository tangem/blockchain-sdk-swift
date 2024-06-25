//
//  BinaryInteger.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension BinaryInteger {
    /// Little-endian = Least significant byte first
    var icpBytes: Data {
        return Data(withUnsafeBytes(of: self, Array.init))
    }
    
    /// from little-endian representation
    static func from(_ data: any DataProtocol) -> Self {
        return Data(data).withUnsafeBytes { $0.load(as: Self.self) }
    }
    
    /// read n bytes from stream and interpret them as little endian
    static func readFrom(_ stream: ByteInputStream) throws -> Self {
        let data = try stream.readNextBytes(MemoryLayout<Self>.size)
        return Self.from(data)
    }
}

extension BigUInt {
    var bytes: Data {
        Data(words.map { $0.icpBytes }.joined())
    }
    
    var bigEndianBytes: Data {
        Data(words.map { $0.icpBytes.reversed() }.reversed().joined())
    }
}

extension FixedWidthInteger {
    /// Big-endian = Most significant byte first
    var bigEndianBytes: Data {
        return bigEndian.icpBytes
    }
}

extension BinaryFloatingPoint {
    /// IEEE754 with little-endian
    var icpBytes: Data { Data(withUnsafeBytes(of: self, Array.init)) }
    
    static func from(_ data: Data) -> Self {
        return data.withUnsafeBytes { $0.load(as: Self.self) }
    }
    
    static func readFrom(_ stream: ByteInputStream) throws -> Self {
        let data = try stream.readNextBytes(MemoryLayout<Self>.size)
        return Self.from(data)
    }
}

extension Data {
    init<T>(from value: T) {
        self = withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) -> Data in
            Data(buffer: UnsafeBufferPointer(start: ptr, count: 1))
        }
    }
    
}
