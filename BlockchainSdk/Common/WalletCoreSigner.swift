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

class WalletCoreSigner: Signer {
    var publicKey: Data {
        walletPublicKey.blockchainKey
    }
    
    private(set) var error: Error?
    
    private let sdkSigner: TransactionSigner
    private let walletPublicKey: Wallet.PublicKey
    
    private var signSubscription: AnyCancellable?
    
    public init(sdkSigner: TransactionSigner, walletPublicKey: Wallet.PublicKey) {
        self.sdkSigner = sdkSigner
        self.walletPublicKey = walletPublicKey
    }
    
    func sign(_ data: Data) -> Data {
        sign([data]).first ?? Data()
    }
    
    public func sign(_ data: [Data]) -> [Data] {
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
