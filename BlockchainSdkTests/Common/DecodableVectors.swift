//
//  DecodableVectors.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 24.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum DecodableVectors: String {
    case blockchain = "blockchain_vectors"
    case validAddress = "valid_address_vectors"
    case derivation = "derivation_vectors"
    case publicKeyAddress = "public_key_address_vectors"
}

// MARK: - Namespace

extension DecodableVectors {
    
    struct ValidAddressVector: Decodable {
        let blockchain: String
        let positive: [String]
        let negative: [String]
    }
    
    struct DerivationVector: Decodable {
        
        struct Derivation: Decodable {
            let tangem: String
            let trust: String
        }
        
        // MARK: - Properties
        
        let blockchain: String
        let derivation: Derivation
        
    }
    
    struct PublicKeyAddressVector: Decodable {
        let blockchain: String
        let publicKey: String
        let address: String
    }
    
    struct MnemonicVector: Decodable {
        let main: String
        let suggestions: [String]?
    }
    
}
