//
// Sui.swift
// BlockchainSdk
//
// Created by Sergei Iakovlev on 28.08.2024
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct Sui {
    public static var SuiGasBudgetScaleUpConstant = Decimal(1000000)
    
    public enum EllipticCurveID: UInt8 {
        case ed25519    = 0x00
        case secp256k1  = 0x01
        case secp256r1  = 0x02
        
        var uint8: UInt8 {
            self.rawValue
        }
    }
    
    public struct CoinType: Codable {
        private static var separator: String { "::" }
        
        public let contract: String
        public let lowerID: String
        public let upperID: String
        
        public static let sui = try! Self(string: "0x2::sui::SUI")
        
        public var string: String {
            [contract, lowerID, upperID].joined(separator: Self.separator)
        }
        
        public init(string: String) throws {
            let elements = string.components(separatedBy: Self.separator)
            
            guard elements.count == 3 else {
                throw SuiError.CoinType.failedDecoding
            }
            
            contract = elements[0]
            lowerID  = elements[1]
            upperID  = elements[2]
        }
        
        public func encode(to encoder: any Encoder) throws {
            try string.encode(to: encoder)
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            try self.init(string: string)
        }
    }
}
