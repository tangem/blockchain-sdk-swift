//
//  TONAddressService.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import SwiftCBOR
import TangemSdk
import TweetNacl

/*
 "User-friendly" address is obtained by generating:

 [1 byte for flag] — Flag changes the way smart-contract reacts to the message.
    Flags of the user-friendly address:
        isBounceable. (0x11 for "bounceable", 0x51 for "non-bounceable")
        isTestnetOnly. Add 0x80 if the address should not be accepted by software running in the production network.
        isUrlSafe. Deprecated flag, as all addresses are url safe now.
 [1 byte for workchain_id] — A signed 8-bit integer with the workchain_id.
    (0x00 for the BaseChain, 0xff for the MasterChain)
    [32 bytes account_id] — 256 bits address inside the workchain. (big-endian)
 [2 bytes for verification] — CRC16-CCITT signature of the previous 34 bytes. (example) In fact, the idea of verification is pretty similar to the Luhn algorithm used in every bank card in the world to prevent you from writing non-existing card number by mistake.
    Finally, you will have 1 + 1 + 32 + 2 = 36 bytes totally!
 
    To get "user-friendly" address, you need to encode the obtained 36 bytes using either:

 base64 (i.e., with digits, upper and lowercase Latin letters, '/' and '+')
 base64url (with '_' and '-' instead of '/' and '+')
 */

public class TONAddressService: AddressService {
    
    let keyPair = try! NaclSign.KeyPair.keyPair(fromSecretKey: Data(hex: "89c22612ff7344ef2ce17e14866cb52beda0c3bb09c2259d9801d63e182c4417968ffcd0678f3f898e20ae03c64c01ee84965e53b0812eb54ed9c96a76709c1a"))
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        let adress = try TONWallet(publicKey: walletPublicKey)
            .getAddress()
            .toString(isUserFriendly: true, isUrlSafe: true, isBounceable: true)
        return adress
    }
    
    public func validate(_ address: String) -> Bool {
        do {
            return TONAddress.isValid(anyForm: address)
        } catch {
            return false
        }
    }
    
}
