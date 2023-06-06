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
        public let derivation: Derivation?

        /// Derived or non-derived key that should be used to create an address in a blockchain
        public var blockchainKey: Data {
            derivation?.derivedKey.publicKey ?? seedKey
        }

        public var derivationPath: DerivationPath? {
            derivation?.path
        }

        public func xpubKey(isTestnet: Bool) -> String? {
            try? derivation?.derivedKey.serialize(for: isTestnet ? .testnet : .mainnet)
        }
        
        public init(seedKey: Data, derivation: Derivation?) {
            self.seedKey = seedKey
            self.derivation = derivation
        }
    }
}

extension Wallet.PublicKey {
    public struct Derivation: Codable, Hashable {
        let path: DerivationPath
        let derivedKey: ExtendedPublicKey
    }
}
