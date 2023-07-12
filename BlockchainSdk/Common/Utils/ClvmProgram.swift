//
//  ClvmProgram.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 11.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

class ClvmNode {
    private(set) var value: Array<Int8>?
    private(set) var left: ClvmNode?
    private(set) var right: ClvmNode?

    init(value: Array<Int8>? = nil, left: ClvmNode? = nil, right: ClvmNode? = nil) {
        self.value = value
        self.left = left
        self.right = right
    }
    
    // MARK: - Hashable
    
    func hash() throws -> Data {
        let hash: Data
        
        if let value = value {
            hash = Data(([Int8()] + value).map { UInt8(bitPattern: $0) }).sha256()
        } else {
            if
                let left = try left?.hash().map({ Int8(bitPattern: $0) }),
                let right = try right?.hash().map({ Int8(bitPattern: $0) })
            {
                hash = Data(([Int8(), Int8()] + left + right).map { .init(bitPattern: $0) }).sha256()
            } else {
                throw NSError()
            }
        }
        
        print(hash.bytes)
        print(hash.hex)
        
        return hash
    }
}

extension ClvmNode {
    struct Iterator<T>: IteratorProtocol {
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
                throw NSError()
            }

            return element
        }
        
        mutating func next(byteCount: Int) throws -> Array<Element> {
            var result = Array<Element>()
            
            for _ in 0..<byteCount {
                guard let next = next() else {
                    throw NSError()
                }
                
                result.append(next)
            }
            
            return result
        }
    }
    
    class Decoder {
        // MARK: - Properties
        
        private(set) var iterator: ClvmNode.Iterator<Int8>
        
        // MARK: - Init
        
        init(programBytes: Array<Int8>) {
            self.iterator = ClvmNode.Iterator(programBytes: programBytes)
        }
        
        // MARK: - Public Implementation
        
        func deserialize() throws -> ClvmNode {
            try deserialize(with: &iterator)
        }
        
        // MARK: - Private Implementation
        
        private func deserialize(with programByteIterator: inout ClvmNode.Iterator<Int8>) throws -> ClvmNode {
            var sizeBytes = Array<Int8>()

            let currentByte = programByteIterator.next()!
            let currentUByte = UInt8(bitPattern: currentByte)

            if currentUByte <= UInt8(0x7F) {
                return ClvmNode(value: [currentByte])
            } else if currentUByte <= UInt8(0xBF) {
                sizeBytes = [currentByte & Int8(0x3F)]
            } else if currentUByte <= UInt8(0xDF) {
                sizeBytes = try [currentByte & Int8(0x1F)] + [programByteIterator.next()]
            } else if currentUByte <= UInt8(0xEF) {
                sizeBytes = try [currentByte & Int8(0x0F)] + programByteIterator.next(byteCount: 2)
            } else if currentUByte <= UInt8(0xF7) {
                sizeBytes = try [currentByte & Int8(0x07)] + programByteIterator.next(byteCount: 3)
            } else if currentUByte <= UInt8(0xFB) {
                sizeBytes = try [currentByte & Int8(0x03)] + programByteIterator.next(byteCount: 4)
            } else if currentUByte == UInt8(0xFF) {
                let left = try deserialize(with: &programByteIterator)
                let right = try deserialize(with: &programByteIterator)
                return ClvmNode(value: nil, left: left, right: right)
            } else {
                throw NSError()
            }

            let size = sizeBytes.count
            let nextBytes = try programByteIterator.next(byteCount: size)
            return ClvmNode(value: nextBytes)
        }
        
    }
}
