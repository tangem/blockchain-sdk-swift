//
//  Chia+Aug.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Bls_Signature

extension Data {
    func hashAugScheme(with publicKey: Data) throws -> Data {
        try Data(hex: BlsSignatureSwift.augSchemeMplG2Map(publicKeyHash: publicKey.hex, messageHash: self.hex))
    }
}
