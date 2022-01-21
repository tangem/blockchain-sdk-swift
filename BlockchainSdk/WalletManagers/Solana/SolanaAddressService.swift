//
//  SolanaAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 11.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Solana_Swift

public class SolanaAddressService: AddressService {
    public func makeAddress(from walletPublicKey: Data) -> String {
        return Base58.encode(walletPublicKey.bytes)
    }
    
    public func validate(_ address: String) -> Bool {
        let publicKey = PublicKey(string: address)
        return publicKey != nil
    }
}
