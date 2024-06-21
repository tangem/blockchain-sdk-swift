//
//  ICPPrincipal.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 21.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ICPPrincipal {
    public let bytes: Data
    public let string: String
    
    public init(_ string: String) throws {
        self.string = string
        self.bytes = try ICPCryptography.decodeCanonicalText(string)
    }
    
    public init(_ bytes: Data) {
        self.bytes = bytes
        self.string = ICPCryptography.encodeCanonicalText(bytes)
    }
}
