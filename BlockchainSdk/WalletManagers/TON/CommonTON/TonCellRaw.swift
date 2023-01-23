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
    
    init(_ rawValue: Array<UInt8> = []) {
        self.rawValue = rawValue
    }
    
    init(_ copy: TonCellRaw) {
        self.rawValue = copy.bytes
        self.cursor = copy.cursor
    }
    
    // MARK: - Implementation
    
    func reWrite(bytes: Array<UInt8>) {
        self.rawValue = bytes
    }
    
    func write(bytes: Array<UInt8>) {
        rawValue.append(contentsOf: bytes)
        cursor = cursor + bytes.bitsCount
    }
    
    func write(bits: [Bit]) {
        rawValue.append(contentsOf: bits.bytes())
        cursor = cursor + bits.count
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
    
    // Set / Get TopUpped Array
    
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
        let ret = TonCellRaw(self)

        let tuRound = (lroundf(Float(ret.cursor) / 8) > 0 ? lroundf(Float(cursor) / 8) : 1)
        var tu = (tuRound * 8) - ret.cursor
        
        if tu > 0 {
            tu = tu - 1
            try ret.write(bit: .one)
            while (tu > 0) {
                tu = tu - 1
                try ret.write(bit: .zero)
            }
        }
        
        ret.reWrite(bytes: Array(ret.bytes[0..<tuRound]))
        return ret.bytes
    }
    
}
