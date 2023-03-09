//
//  WalletCoreSigner.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 03.02.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//
import Combine

import TangemSdk
import WalletCore

// This class implements a bridge between Tangem SDK and TrustWallet's WalletCore library
// It is implemented with several restrictions in mind, mainly lack of compatibility between
// C++ and Swift exceptions and the way async/await functions work
class WalletCoreSigner: Signer {
    var publicKey: Data {
        walletPublicKey.blockchainKey
    }
    
    private(set) var error: Error?
    
    private let sdkSigner: TransactionSigner
    private let walletPublicKey: Wallet.PublicKey
    
    private var signSubscription: AnyCancellable?
    
    init(sdkSigner: TransactionSigner, walletPublicKey: Wallet.PublicKey) {
        self.sdkSigner = sdkSigner
        self.walletPublicKey = walletPublicKey
    }
    
    func sign(_ data: Data) -> Data {
        sign([data]).first ?? Data()
    }
    
    func sign(_ data: [Data]) -> [Data] {
        // We need this function to freeze the current thread until the TangemSDK operation is complete.
        // We need this because async/await concepts are not compatible between C++ and Swift.
        // Because this function freezes the current thread make sure to call WalletCore's AnySigner from a non-GUI thread.
        
        var signedData: [Data] = []
        
        let operation = BlockOperation { [weak self] in
            guard let self else { return }
            
            let group = DispatchGroup()
            group.enter()
            
            self.signSubscription = self.sdkSigner.sign(hashes: data, walletPublicKey: self.walletPublicKey)
                .sink { completion in
                    if case .failure(let error) = completion {
                        self.error = error
                    }
                    
                    group.leave()
                } receiveValue: { data in
                    signedData = data
                }
            
            group.wait()
        }
        
        operation.start()
        operation.waitUntilFinished()
        
        return signedData
    }
}
