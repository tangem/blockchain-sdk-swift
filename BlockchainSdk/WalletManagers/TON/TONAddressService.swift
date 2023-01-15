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
    
    public func makeAddress(from walletPublicKey: Data) throws -> String {
        print(walletPublicKey.hexDescription)
        print(walletPublicKey.map { Byte($0) })
        print(walletPublicKey.count)
        
        return walletPublicKey.hexString
//        try walletPublicKey.validateAsEdKey()
//
//        var combineAddress = Data()
//        combineAddress.append(Byte(AddressTag.NON_BOUNCEABLE.rawValue))
//        combineAddress.append(Byte(0x00))
//        combineAddress.append(walletPublicKey.map { Byte($0) }, count: walletPublicKey.count)
//        let checksum = combineAddress.crc16()
//        combineAddress.append(checksum)
//
//        print(combineAddress.base64EncodedString())
//        print(walletPublicKey.base64EncodedString())
//
//        return combineAddress.base64EncodedString()
    }
    
    public func validate(_ address: String) -> Bool {
//        guard
//            address.count == 48,
//            let rawData = Data(base64EncodedURLSafe: address),
//            rawData.count == 36
//        else {
//            return false
//        }
        
//        let addrData = rawData[0...33]
//        let crcData = rawData[34...35]
//        let calcedCrc = addrData.crc16()
        
//        print(addrData.crc16())
//
//        let hashPart = addrData.subdata(in: 2..<34)
//
//        print(hashPart.map { Byte($0) })
//        print(hashPart.hex)
        
        return true
    }
    
}

public extension Data {
    init?(base64EncodedURLSafe string: String, options: Base64DecodingOptions = []) {
        let string = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        self.init(base64Encoded: string, options: options)
    }
}

public extension TONAddressService {
    
    enum AdressLen: Int {
        case b64UserFriendlyAddressLen = 48;
        case userFriendlyAddressLen = 36;
    }
    
    enum AddressTag : UInt8 {
        case BOUNCEABLE = 0x11
        case NON_BOUNCEABLE = 0x51
        case TEST_ONLY = 0x80
    }
    
    enum WorkchainType: Int {
        case Masterchain = -1
        case Basechain = 0
    }
    
    struct Address {
        
        let pubKey: Data
        
        let bounceable: Bool
        
        let testOnly: Bool
        
        init(pubKey: Data, bounceable: Bool, testOnly: Bool) {
            self.pubKey = pubKey
            self.bounceable = bounceable
            self.testOnly = testOnly
        }
        
        func make() -> String {
            return ""
        }
        
    }
    
}

//std::string Address::string(bool userFriendly, bool bounceable, bool testOnly)  const {
//     if (!userFriendly) {
//         return AddressImpl::to_string(addressData);
//     }
//
//     Data data;
//     Data hashData(addressData.hash.begin(), addressData.hash.end());
//
//     byte tag = bounceable ? AddressTag::BOUNCEABLE : AddressTag::NON_BOUNCEABLE;
//     if (testOnly) {
//         tag |= AddressTag::TEST_ONLY;
//     }
//
//     append(data, tag);
//     append(data, addressData.workchainId);
//     append(data, hashData);
//
//     const uint16_t crc16 = Crc::crc16(data.data(), (uint32_t) data.size());
//     append(data, (crc16 >> 8) & 0xff);
//     append(data, crc16 & 0xff);
//
//     return Base64::encodeBase64Url(data);
//}

//UQAliom2DM5+szOb9NuKjagVOqK2SJ0izFlOUP32Jtp69TqJ
//5100258A89B60CCE7EB3339BF4DB8A8DA8153AA2B6489D22CC594E50FDF626DA7AF53A89
//258A89B60CCE7EB3339BF4DB8A8DA8153AA2B6489D22CC594E50FDF626DA7AF5
//995b3e6c86d4126f52a19115ea30d869da0b2e5502a19db1855eeb13081b870b
