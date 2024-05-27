//
//  TONProviderResponse.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 26.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Base TON provider response
struct TONProviderResponse<R: Decodable>: Decodable {
    
    /// Success status
    let ok: Bool
    
    /// Decodable result
    let result: R
    
    /// Description error
    let error: String?
    
    /// Response code (Not transport)
    let code: Int?
    
    enum CodingKeys: CodingKey {
        case ok
        case result
        case error
        case code
    }
    
    init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<TONProviderResponse<R>.CodingKeys> = try decoder.container(keyedBy: TONProviderResponse<R>.CodingKeys.self)
        
        self.ok = try container.decode(Bool.self, forKey: TONProviderResponse<R>.CodingKeys.ok)
        self.result = try container.decode(R.self, forKey: TONProviderResponse<R>.CodingKeys.result)
        self.error = try container.decodeIfPresent(String.self, forKey: TONProviderResponse<R>.CodingKeys.error)
        self.code = try container.decodeIfPresent(Int.self, forKey: TONProviderResponse<R>.CodingKeys.code)
        
    }
    
}
