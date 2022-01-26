//
//  PolkadotAddressService.swift
//  BlockchainSdk
//
//  Created by Andrey Chukavin on 26.01.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

class PolkadotAddressService: AddressService {
    // https://wiki.polkadot.network/docs/build-protocol-info#addresses
    enum AddressPrefix: UInt8 {
        case polkadot = 0
        case kusama = 2
        case westend = 42
    }
    
    private let addressPrefix: AddressPrefix
    private let checksumLength = 2
    private let ss58prefix = "SS58PRE".data(using: .utf8) ?? Data()
    
    init(addressPrefix: AddressPrefix) {
        self.addressPrefix = addressPrefix
    }
    
    func makeAddress(from walletPublicKey: Data) throws -> String {
        var addressData = Data(addressPrefix.rawValue) + walletPublicKey
        
        let checksumMessage = ss58prefix + addressData
        let checksum = blake2checksum(checksumMessage)
        addressData.append(checksum)
                
        return String(base58: addressData, alphabet: Base58String.btcAlphabet)
    }
    
    func validate(_ address: String) -> Bool {
        guard let data = address.base58DecodedData else { return false }
        
        let expectedChecksum = data.suffix(checksumLength)
        let addressData = data.dropLast(checksumLength)
        
        let checksumMessage = ss58prefix + addressData
        let checksum = blake2checksum(checksumMessage)
        
        return checksum == expectedChecksum
    }
    
    private func blake2checksum(_ message: Data) -> Data {
        let hash = Data(Sodium().genericHash.hash(message: message.bytes, outputLength: 64) ?? [])
        let checksum = hash.prefix(checksumLength)
        return checksum
    }
}
