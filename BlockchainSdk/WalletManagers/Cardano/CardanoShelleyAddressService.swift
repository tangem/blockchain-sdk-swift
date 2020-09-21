//
//  CardanoShelleyAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 21.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import SwiftCBOR
import CryptoSwift

public class CardanoShelleyAddressService: AddressService, CardanoAddressDecoder {
    private static let ADDRESS_HEADER_BYTE = Data([UInt8(97)])
    fileprivate static let BECH32_HRP = "addr1"
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        let publicKeyHash = Sodium().genericHash.hash(message: walletPublicKey.toBytes, outputLength: 28)!
        let addressBytes = CardanoShelleyAddressService.ADDRESS_HEADER_BYTE + publicKeyHash
        let bech32 = Bech32()
        let walletAddress = bech32.encode("addr", values: Data(addressBytes))
        return walletAddress
    }
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty else {
            return false
        }
        
        guard address.starts(with: CardanoShelleyAddressService.BECH32_HRP) else {
            return false
        }
        
        if let _ = try? Bech32().decodeLong(address) {
            return true
        } else {
            return false
        }
    }
    
    public func decode(_ address: String) -> Data? {
        let bech32 = Bech32()
        guard let decoded = try? bech32.decodeLong(address) else {
            return nil
        }
        
        guard let converted = try? bech32.convertBits(data: Array(decoded.checksum), fromBits: 5, toBits: 8, pad: false) else {
            return nil
        }
        
        return Data(converted)
    }
}

protocol CardanoAddressDecoder {
    func decode(_ address: String) -> Data?
}

struct CardanoAddress {
    static func decode(_ address: String) -> Data? {
        if address.starts(with: CardanoShelleyAddressService.BECH32_HRP) {
            return CardanoShelleyAddressService().decode(address)
        } else {
            return CardanoAddressService().decode(address)
        }
    }
    
    static func validate(_ address: String) -> Bool {
        if address.starts(with: CardanoShelleyAddressService.BECH32_HRP) {
            return CardanoShelleyAddressService().validate(address)
        } else {
            return CardanoAddressService().validate(address)
        }
    }
}
