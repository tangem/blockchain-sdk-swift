//
//  Common+Types.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Array where Element == UInt8 {
    
    var cursor: Int {
        return self.count
    }
    
    func checkRange(_ n: Int) throws {
        if n > self.count {
            throw NSError()
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
    
    func getTopUppedArray() -> Array<UInt8> {
        return [52]
    }
    
}

extension Array where Element == Bit {
    
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
    
    var bits: [Bit] {
        // Make variable
        var bytes = self
        // Fill an array of bits with zeros to the fixed width integer length
        var bits = [Bit](repeating: .zero, count: self.bitWidth)
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

extension UInt8 {
    
    var nonZeroBits: [Bit] {
        // Make variable
        var bytes = self
        // Fill an array of bits with zeros to the fixed width integer length
        var bits = [Bit](repeating: .zero, count: self.trailingZeroBitCount)
        // Run through each bit (LSB first)
        for i in 0..<self.nonzeroBitCount {
            let currentBit = bytes & 0x01
            if currentBit != 0 {
                bits[i] = .one
            }

            bytes >>= 1
        }

        return bits
    }
    
}

extension BinaryInteger {
    
    var binaryDescription: String {
        var binaryString = ""
        var internalNumber = self
        var counter = 0

        for _ in (1...self.bitWidth) {
            binaryString.insert(contentsOf: "\(internalNumber & 1)", at: binaryString.startIndex)
            internalNumber >>= 1
            counter += 1
            if counter % 4 == 0 {
                binaryString.insert(contentsOf: " ", at: binaryString.startIndex)
            }
        }

        return binaryString
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
