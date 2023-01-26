//
//  TONCellBytes.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import CryptoSwift
import Foundation

public class TonCellRaw {
    
    // MARK: - Typealias
    
    typealias Bit = CryptoSwift.Bit
    
    // MARK: - Public Properties
    
    var bytes: Array<UInt8> {
        return rawValue
    }
    
    var length: Int {
        bytes.count
    }
    
    var cursor: Int = 0
    
    // MARK: - Private Properties
    
    private var rawValue: Array<UInt8>
    
    // MARK: - Init
    
    init(_ rawValue: Array<UInt8>? = nil) {
        self.rawValue = rawValue ?? [UInt8](repeating: 0, count: 128)
    }
    
    init(length: Int?) {
        self.rawValue = [UInt8](repeating: 0, count: Int(ceilf(Float(length ?? 0) / 8)))
    }
    
    init(copy: TonCellRaw) {
        self.rawValue = copy.bytes
        self.cursor = copy.cursor
    }
    
    // MARK: - Writing Implementation
    
    func rewrite(bytes: Array<UInt8>) {
        self.rawValue = bytes
    }
    
    func write(bytes: Array<UInt8>) throws {
        for byte in bytes {
            try write(bits: byte.bits())
        }
    }
    
    func write(bytes: Array<UInt8>, _ limit: Int) throws {
        for byte in bytes {
            try byte.bits().forEach {
                guard self.cursor < limit else {
                    return
                }
                
                try self.write(bit: $0)
            }
        }
    }
    
    func write(bits: [Bit]) throws {
        try bits.forEach {
            try self.write(bit: $0)
        }
    }
    
    func write(bit: Bit) throws {
        switch bit {
        case .zero:
            try off(cursor)
        case .one:
            try on(cursor)
        }
        
        cursor = cursor + 1
    }
    
    /**
     * Write unsigned int
     * @param number  {number | BN}
     * @param bitLength  {number}  size of uint in bits
     */
    func write(uint num: UInt, _ bitLength: Int) throws {
        if bitLength == 0 || num.bits[0..<bitLength].reversed().count > bitLength {
            if num == 0 { return }
            throw NSError()
        }
        
        for i in num.bits[0..<bitLength].reversed() {
            try self.write(bit: i == .one)
        }
    }
    
    /**
     * Write unsigned int
     * @param number  {number | BN}
     * @param bitLength  {number}  size of uint in bits
     */
    func write(uint8 num: UInt8) throws {
        try write(uint: UInt(num), 8)
    }
    
    /**
     * Write bit and increase cursor
     * @param b  {boolean | number}
     */
    func write(bit: Bool) throws {
        if bit {
            try on(cursor)
        } else {
            try off(cursor)
        }
        cursor = cursor + 1
    }
    
    /**
     * Write signed int
     * @param number  {number | BN}
     * @param bitLength  {number}  size of int in bits
     */
    func write(int num: Int, _ bitLength: Int) throws {
        if bitLength == 1 {
            if num == -1 {
                try write(bit: true)
                return
            }
            if num == 0 {
                try write(bit: false)
                return
            }
            
            throw NSError()
        } else {
            if num < 0 {
                throw NSError()
            } else {
                try write(bit: false)
                try write(uint: UInt(num), bitLength-1)
            }
        }
    }
    
    /**
     * write another BitString to this BitString
     * @param anotherBitString  {BitString}
     */
    func write(bit string: String) throws {
        try string.forEach {
            try self.write(bit: $0 == "1")
        }
    }
    
    /**
     * @private
     * @param n {number}
     */
    func checkRange(_ n: Int) throws {
        if n > rawValue.count * 8 {
            throw NSError()
        }
    }
    
    /**
     * Set bit value to 1 at position `n`
     * @param n {number}
     */
    func on(_ n: Int) throws {
        try checkRange(n)
        rawValue[(n / 8) | 0] |= 1 << (7 - (n % 8));
    }
    
    /**
     * Set bit value to 0 at position `n`
     * @param n {number}
     */
    func off(_ n: Int) throws {
        try checkRange(n)
        rawValue[(n / 8) | 0] &= ~(1 << (7 - (n % 8)))
    }
    
    /**
     * @param n {number}
     * @return {boolean}    bit value at position `n`
     */
    func positiion(_ n: Int) throws -> Bool {
        return (rawValue[(n / 8) | 0] & (1 << (7 - (n % 8)))) > 0
    }
    
    /**
     * @return {number}
     */
    func getFreeBits() -> Int {
        return (rawValue.count * 8) - cursor
    }
    
    /**
     * @return {number}
     */
    func getUsedBits() -> Int {
        return cursor
    }
    
    // Set / Get TopUpped Array
    
    ///
    func setTopUppedArray(_ array: Array<UInt8>, fullfilledBytes: Bool = true) throws {
        let length = array.count * 8
        self.rawValue = array
        self.cursor = length
        
        if fullfilledBytes || self.rawValue.count == 0 {
            return
        } else {
            var foundEndBit = false
            
            for _ in 0..<7 {
                cursor = cursor - 1
                
                if try positiion(cursor) {
                    foundEndBit = true
                    try off(cursor)
                    return
                }
            }
            
            if !foundEndBit {
                throw NSError()
            }
        }
    }
    
    ///
    func getTopUppedArray() throws -> Array<UInt8> {
        let ret = TonCellRaw(copy: self)

        let tuRound = Int(ceilf(Float(cursor) / 8))
        var tu = (tuRound * 8) - ret.cursor
        
        if tu > 0 {
            tu = tu - 1
            try ret.write(bit: .one)
            while (tu > 0) {
                tu = tu - 1
                try ret.write(bit: .zero)
            }
        }
        
        ret.rewrite(bytes: Array(ret.bytes[0..<tuRound]))
        return ret.bytes
    }
    
    /**
     * @param address {Address | null}
     */
    func write(address: TONAddress? = nil) throws {
        if let address = address {
            try write(uint: 2, 2)
            try write(uint: 0, 1)
            try write(int: address.wc, 8)
            try write(bytes: address.hashPart.bytes)
        } else {
            try write(uint: 0, 2)
        }
    }
    
    /**
     * @param amount  {number | BN} in nanograms
     */
    func write(grams amount: Int) throws {
        if amount == 0 {
            try write(uint: 0, 4)
        } else {
            let l = ceilf(Float(amount.hex.count) / 2)
            try write(uint: UInt(l), 4);
            try write(uint: UInt(amount), Int(l) * 8);
        }
    }
    
}
