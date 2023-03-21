//
//  TrustCoreSignerTesterUtility.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 21.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import Combine
import TangemSdk
import CryptoKit

@testable import BlockchainSdk

@available(iOS 13.0, *)
public class TrustCoreSignerTesterUtility {
    
    private var privateKey: Curve25519.Signing.PrivateKey
    
    init(privateKey: Curve25519.Signing.PrivateKey) {
        self.privateKey = privateKey
    }
    
}

extension TrustCoreSignerTesterUtility: TransactionSigner {
    public func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }
                
                TransactionSizeTesterUtility().testTxSizes(hashes)
                
                do {
                    let signatures = try hashes.map {
                        try Curve25519.Signing.PrivateKey(rawRepresentation: self.privateKey.rawRepresentation).signature(for: $0)
                    }
                    promise(.success(signatures))
                } catch {
                    promise(.failure(NSError()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func sign(hash: Data, walletPublicKey: BlockchainSdk.Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        sign(hashes: [hash], walletPublicKey: walletPublicKey)
            .map {
                $0.first ?? Data()
            }
            .eraseToAnyPublisher()
    }
}
