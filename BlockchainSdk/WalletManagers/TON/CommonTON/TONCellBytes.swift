//
//  TONCellBytes.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 22.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public class TonCellBytes {
    
    var bytes: Array<UInt8> {
        return wrapBytes
    }
    
    var length: Int {
        bytes.count
    }
    
    var cursor: Int = 0
    
    // MARK: - Implementation
    
    func write(bytes: Array<UInt8>) {
        self.bytes.append(bytes)
    }
    
    // MARK: - Private Properties
    
    private var wrapBytes: Array<UInt8>
    
    // MARK: - Init
    
    init(_ wrapBytes: Array<UInt8>) {
        self.wrapBytes = wrapBytes
    }
    
}
