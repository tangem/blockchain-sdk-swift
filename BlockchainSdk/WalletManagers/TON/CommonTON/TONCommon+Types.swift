//
//  Common+Types.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation

extension Array where Element == UInt8 {
    
    var bitsCount: Int {
        self.map { $0.bits.count }.reduce(0, +)
    }
    
    func checkRange(_ n: Int) throws {
        if n > self.count {
            throw TONError.empty
        }
    }
    
    func get(_ n: Int) -> Bool {
        return (self[(n / 8) | 0] & (1 << (7 - (n % 8)))) > 0
    }
    
    mutating func on(_ n: Int) throws {
        self[(n / 8) | 0] |= 1 << (7 - (n % 8));
    }
    
    mutating func off(_ n: Int) throws {
        self[(n / 8) | 0] &= ~(1 << (7 - (n % 8)))
    }
    
}

extension Array where Element == CryptoSwift.Bit {
    
    func bytes() -> [UInt8] {
        let bits = self
        let numBits = bits.count
        let numBytes = (numBits + 7)/8
        var bytes = [UInt8](repeating: 0, count: numBytes)

        for (index, bit) in bits.enumerated() {
            if bit == .one {
                bytes[index / 8] += 1 << (7 - index % 8)
            }
        }

        return bytes
    }
    
}

extension FixedWidthInteger {
    
    var bits: [CryptoSwift.Bit] {
        // Make variable
        var bytes = self
        // Fill an array of bits with zeros to the fixed width integer length
        var bits = [CryptoSwift.Bit](repeating: .zero, count: self.bitWidth)
        // Run through each bit (LSB first)
        for i in 0..<self.bitWidth {
            let currentBit = bytes & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }

            bytes >>= 1
        }

        return bits
    }
    
}

extension Int {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Int>.size)
    }
}

extension UInt8 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt8>.size)
    }
}

extension UInt16 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt16>.size)
    }
}

extension UInt32 {
    
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt32>.size)
    }
    
    var byteArrayLittleEndian: [UInt8] {
        return [
            UInt8((self & 0xFF000000) >> 24),
            UInt8((self & 0x00FF0000) >> 16),
            UInt8((self & 0x0000FF00) >> 8),
            UInt8(self & 0x000000FF)
        ]
    }
    
}

func concatBytes(_ a: Array<UInt8>, _ b: Array<UInt8>) -> Array<UInt8> {
    var c = Array<UInt8>()
    c.append(contentsOf: a)
    c.append(contentsOf: b)
    return c
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

extension String {
    
    func generateTONAddress() throws -> TONAddress {
        return try .init(self)
    }
    
}

extension Bool {
    
    var bit: CryptoSwift.Bit {
        return self ? .one : .zero
    }
    
}

extension TONCell {
    
    func hashData() throws -> Data {
        try Data(self.hash())
    }
    
}
