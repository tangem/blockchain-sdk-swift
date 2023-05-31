//
//  Wallet+PublicKey.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension Wallet {
    public struct PublicKey: Codable, Hashable {
        public let seedKey: Data
        public let derivation: Derivation
                
        public var derivedKey: ExtendedPublicKey? {
            switch derivation {
            case .none:
                return nil
            case .derivation(_, let derivedKey):
                return derivedKey
            }
        }
        
        public var derivationPath: DerivationPath? {
            switch derivation {
            case .none:
                return nil
            case .derivation(let path, _):
                return path
            }
        }
        
        /// Derived or non-derived key that should be used to create an address in a blockchain
        public var blockchainKey: Data {
            switch derivation {
            case .none:
                return seedKey
            case .derivation(_, let derivedKey):
                return derivedKey.publicKey
            }
        }
        
        public init(seedKey: Data, derivation: Derivation) {
            self.seedKey = seedKey
            self.derivation = derivation
        }
    }
}

extension Wallet.PublicKey {
    public enum Derivation: Codable, Hashable {
        case none
        case derivation(path: DerivationPath, derivedKey: ExtendedPublicKey)
    }
}
