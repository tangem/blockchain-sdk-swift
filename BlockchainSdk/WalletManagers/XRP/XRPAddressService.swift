//
//  XRPAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 09.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
public class XRPAddressService: AddressService {
    let curve: EllipticCurve
    
    init(curve: EllipticCurve) {
        self.curve = curve
    }
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        var key: Data
        switch curve {
        case .secp256k1:
            key = try Secp256k1Key(with: walletPublicKey).compress()
        case .ed25519:
            try walletPublicKey.validateAsEdKey()
            key = [UInt8(0xED)] + walletPublicKey
        default:
            fatalError("unsupported curve")
        }
        let input = key.sha256Ripemd160
        let buffer = [0x00] + input
        let checkSum = Data(buffer.sha256().sha256()[0..<4])
        let walletAddress = XRPBase58.getString(from: buffer + checkSum)
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        if XRPSeedWallet.validate(address: address) {
            return true
        }
        
        if let _ = try? XRPAddress.decodeXAddress(xAddress: address) {
            return true
        }
        
        return false
    }
}
