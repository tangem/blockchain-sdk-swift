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

public class WalletCoreSigner: Signer {
    private(set) var error: Error?
    
    private let sdkSigner: TransactionSigner
    private let publicKey: Wallet.PublicKey
    
    private var signSubscription: AnyCancellable?
    
    public init(sdkSigner: TransactionSigner, publicKey: Wallet.PublicKey) {
        self.sdkSigner = sdkSigner
        self.publicKey = publicKey
    }
    
    public func sign(_ data: Data) -> Data {
        var signedData: Data?
        
        let operation = BlockOperation { [weak self] in
            guard let self else { return }
            
            let group = DispatchGroup()
            group.enter()
            
            self.signSubscription = self.sdkSigner.sign(hash: data, walletPublicKey: self.publicKey)
                .sink { completion in
                    group.leave()
                    
                    if case .failure(let error) = completion {
                        self.error = error
                    }
                } receiveValue: { data in
                    signedData = data
                }
            
            group.wait()
        }
        
        operation.start()
        operation.waitUntilFinished()

        return signedData ?? Data()
    }
}
