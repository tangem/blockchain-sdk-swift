//
//  ByteInputStream.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class ByteInputStream {
    private enum ByteInputStreamError: Error {
        case readError
    }
    private let stream: InputStream
    private let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
    
    var hasBytesAvailable: Bool { stream.hasBytesAvailable }
    
    init(_ data: Data) {
        stream = InputStream(data: data)
        stream.open()
    }
    
    deinit {
        stream.close()
        buffer.deallocate()
    }
    
    func readNextByte() throws -> UInt8  {
        let bytesRead = stream.read(buffer, maxLength: 1)
        guard bytesRead == 1 else {
            throw ByteInputStreamError.readError
        }
        return buffer.pointee
    }
    
    func readNextBytes(_ n: Int) throws -> Data {
        try Data((0..<n).map { _ in try readNextByte() })
    }
}
