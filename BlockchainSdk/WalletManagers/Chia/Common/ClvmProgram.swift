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

class ClvmNode {
    private let atom: Array<Byte>?
    private let left: ClvmNode?
    private let right: ClvmNode?

    init(atom: Array<Byte>? = nil, left: ClvmNode? = nil, right: ClvmNode? = nil) {
        self.atom = atom
        self.left = left
        self.right = right
    }
    
    // MARK: - Hashable
    
    func hash() throws -> Data {
        if let value = atom {
            return Data([1] + value).sha256()
        } else if let left = try left?.hash(), let right = try right?.hash() {
            return Data([2] + left + right).sha256()
        }
        
        throw NSError()
    }
}

extension ClvmNode {
    class Decoder {
        // MARK: - Properties
        
        private var iterator: ClvmNode.Iterator<Byte>
        
        // MARK: - Init
        
        init(programBytes: Array<Byte>) {
            self.iterator = ClvmNode.Iterator(programBytes: programBytes)
        }
        
        // MARK: - Public Implementation
        
        func deserialize() throws -> ClvmNode {
            try deserialize(with: &iterator)
        }
        
        // MARK: - Private Implementation
        
        private func deserialize(with programByteIterator: inout ClvmNode.Iterator<Byte>) throws -> ClvmNode {
            var sizeBytes = Array<Byte>()

            let currentByte = programByteIterator.next()!

            if currentByte <= 0x7F {
                return ClvmNode(atom: [currentByte])
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
                return ClvmNode(atom: nil, left: left, right: right)
            } else {
                throw DecoderError.errorCompareCurrentByte
            }

            let size = sizeBytes.toInt()
            let nextBytes = try programByteIterator.next(byteCount: size)
            return ClvmNode(atom: nextBytes)
        }
    }
    
    enum DecoderError: Error {
        case errorCompareCurrentByte
    }
}

extension ClvmNode {
    private struct Iterator<T>: IteratorProtocol {
        private(set) var programBytes: Array<T>
        
        mutating func next() -> T? {
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
            try (0 ..< byteCount).map { _ in
                guard let next = next() else {
                    throw IteratorError.undefinedElement
                }
                
                return next
            }
        }
    }
    
    enum IteratorError: Error {
        case undefinedElement
    }
}
