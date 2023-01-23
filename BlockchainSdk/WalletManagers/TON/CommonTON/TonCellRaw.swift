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
    
    // MARK: - Update Implementation
    
    func fill(bytes: Array<UInt8>) {
        self.rawValue = bytes
    }
    
    func append(bytes: Array<UInt8>) {
        self.rawValue.append(contentsOf: bytes)
    }
    
    func append(bits: [Bit]) throws {
        self.rawValue.append(contentsOf: bits.bytes())
        try bits.forEach {
            try self.write(bit: $0)
        }
    }
    
    // MARK: - Writing Implementation
    
    func rewrite(bytes: Array<UInt8>) {
        self.rawValue = bytes
    }
    
    func write(bytes: Array<UInt8>) {
        rawValue.append(contentsOf: bytes)
        cursor = cursor + bytes.bitsCount
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
        if bitLength == 0 || num.bits[0..<bitLength].count > bitLength {
            if num == 0 { return }
            throw NSError()
        }
        
        let s = num.bits[0..<bitLength]
        
        for i in 0..<bitLength {
            try self.write(bit: s[i] == .one)
        }
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
    func write(int: Int, _ bitLength: Int) throws {
        throw NSError()
//        number = new BN(number);
//        if (bitLength == 1) {
//            if (number == -1) {
//                this.writeBit(true);
//                return;
//            }
//            if (number == 0) {
//                this.writeBit(false);
//                return;
//            }
//            throw Error("Bitlength is too small for number");
//        } else {
//            if (number.isNeg()) {
//                this.writeBit(true);
//                const b = new BN(2);
//                const nb = b.pow(new BN(bitLength - 1));
//                this.writeUint(nb.add(number), bitLength - 1);
//            } else {
//                this.writeBit(false);
//                this.writeUint(number, bitLength - 1);
//            }
//        }
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
        let ret = TonCellRaw(self)

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
    
    //addr_none$00 = MsgAddressExt;
    //addr_std$10 anycast:(Maybe Anycast)
    // workchain_id:int8 address:uint256 = MsgAddressInt;
    /**
     * @param address {Address | null}
     */
    func write(address: TONAddress? = nil) throws {
        if let address = address {
            try write(uint: 2, 2)
            try write(uint: 0, 1)
            try write(int: address.wc, 8)
            write(bytes: address.hashPart.bytes)
        } else {
            try write(uint: 0, 2)
        }
    }
    
}
