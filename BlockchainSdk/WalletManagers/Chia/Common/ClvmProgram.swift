//
//  ClvmProgram.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 11.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import CryptoSwift

class ClvmProgram {
    private let atom: Array<Byte>?
    private let left: ClvmProgram?
    private let right: ClvmProgram?
    
    // MARK: - Init

    init(atom: Array<Byte>? = nil, left: ClvmProgram? = nil, right: ClvmProgram? = nil) {
        self.atom = atom
        self.left = left
        self.right = right
    }
    
    // MARK: - Static
    
    static func from(long: Int64) -> ClvmProgram {
        return .init(atom: long.chiaEncode().bytes)
    }
    
    static func from(bytes: Array<Byte>) -> ClvmProgram {
        return .init(atom: bytes, left: nil, right: nil)
    }
    
    static func from(list: [ClvmProgram]) -> ClvmProgram {
        var result: ClvmProgram? = nil
        
        for item in list.reversed() {
            result = ClvmProgram(atom: nil, left: item, right: result)
        }
        
        return result ?? .init()
    }
    
    // MARK: - Hashable
    
    func hash() throws -> Data {
        let hash: Data
        
        if let value = atom {
            hash = Data([1] + value).sha256()
        } else {
            if let left = try left?.hash(), let right = try right?.hash() {
                hash = Data([2] + left + right).sha256()
            } else {
                throw NSError()
            }
        }
        
        return hash
    }
    
    func serialize() throws -> Data {
        if let atom = atom {
            if atom.isEmpty {
                return Data(Byte(0x80))
            } else if atom.count == 1 && atom[0] <= 0x7F {
                return Data(atom[0])
            } else {
                let size = UInt64(atom.count)
                var result = [Byte]()
                
                if size < 0x40 {
                    result.append(Byte(size & 0x0F))
                } else if size < 0x2000 {
                    result.append(Byte((size >> 8) | 0xC0))
                    result.append(Byte(size & 0xFF))
                } else if size < 0x100000 {
                    result.append(Byte((size >> 16) & 0xE0))
                    result.append(Byte((size >> 8) & 0xFF))
                    result.append(Byte(size & 0xFF))
                } else if size < 0x8000000 {
                    result.append(Byte((size >> 24) | 0xF0))
                    result.append(Byte((size >> 16) & 0xFF))
                    result.append(Byte((size >> 8) & 0xFF))
                    result.append(Byte(size & 0xFF))
                } else if size < 0x400000000 {
                    result.append(Byte((size >> 32) | 0xF8))
                    result.append(Byte((size >> 24) & 0xFF))
                    result.append(Byte((size >> 16) & 0xFF))
                    result.append(Byte((size >> 8) & 0xFF))
                    result.append(Byte(size & 0xFF))
                } else {
                    throw EncoderError.manyBytesToEncode
                }
                
                result.append(contentsOf: atom)
                return Data(result)
            }
        } else {
            if let left = left, let right = right {
                return try Data(Byte(0xff)) + left.serialize() + right.serialize()
            } else {
                throw EncoderError.undefinedEncodeException
            }
        }
    }
    
    enum EncoderError: Error {
        case manyBytesToEncode
        case undefinedEncodeException
    }
}

extension ClvmProgram {
    class Decoder {
        // MARK: - Properties
        
        private var iterator: ClvmProgram.Iterator<Byte>
        
        // MARK: - Init
        
        init(programBytes: Array<Byte>) {
            self.iterator = ClvmProgram.Iterator(programBytes: programBytes)
        }
        
        // MARK: - Public Implementation
        
        func deserialize() throws -> ClvmProgram {
            try deserialize(with: &iterator)
        }
        
        // MARK: - Private Implementation
        
        private func deserialize(with programByteIterator: inout ClvmProgram.Iterator<Byte>) throws -> ClvmProgram {
            var sizeBytes = Array<Byte>()

            let currentByte = programByteIterator.next()!

            if currentByte <= 0x7F {
                return ClvmProgram(atom: [currentByte])
            } else if currentByte <= 0xBF {
                sizeBytes = [currentByte & 0x3F]
            } else if currentByte <= 0xDF {
                sizeBytes = try [currentByte & 0x1F] + [programByteIterator.next()]
            } else if currentByte <= 0xEF {
                sizeBytes = try [currentByte & 0x0F] + programByteIterator.next(byteCount: 2)
            } else if currentByte <= 0xF7 {
                sizeBytes = try [currentByte & 0x07] + programByteIterator.next(byteCount: 3)
            } else if currentByte <= 0xFB {
                sizeBytes = try [currentByte & 0x03] + programByteIterator.next(byteCount: 4)
            } else if currentByte == 0xFF {
                let left = try deserialize(with: &programByteIterator)
                let right = try deserialize(with: &programByteIterator)
                return ClvmProgram(atom: nil, left: left, right: right)
            } else {
                throw DecoderError.errorCompareCurrentByte
            }

            let size = sizeBytes.toInt()
            let nextBytes = try programByteIterator.next(byteCount: size)
            return ClvmProgram(atom: nextBytes)
        }
    }
    
    enum DecoderError: Error {
        case errorCompareCurrentByte
    }
}

extension ClvmProgram {
    private struct Iterator<T>: IteratorProtocol {
        typealias Element = T
        
        private(set) var programBytes: Array<Element>
        
        mutating func next() -> Element? {
            defer {
                if !programBytes.isEmpty { programBytes.removeFirst() }
            }

            return programBytes.first
        }
        
        mutating func next() throws -> Element {
            defer {
                if !programBytes.isEmpty { programBytes.removeFirst() }
            }
            
            guard let element = programBytes.first else {
                throw IteratorError.undefinedElement
            }

            return element
        }
        
        mutating func next(byteCount: Int) throws -> Array<Element> {
            var result = Array<Element>()
            
            for _ in 0..<byteCount {
                guard let next = next() else {
                    throw IteratorError.undefinedElement
                }
                
                result.append(next)
            }
            
            return result
        }
    }
    
    enum IteratorError: Error {
        case undefinedElement
    }
}
