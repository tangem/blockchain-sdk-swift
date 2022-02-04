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
    private let network: PolkadotNetwork
    
    init(network: PolkadotNetwork) {
        self.network = network
    }
    
    func makeAddress(from walletPublicKey: Data) throws -> String {
        PolkadotAddress(publicKey: walletPublicKey, network: network).string
    }
    
    func validate(_ address: String) -> Bool {
        PolkadotAddress(string: address, network: network) != nil
    }
}


struct PolkadotAddress {
    let string: String

    static private let networkLength = 1
    static private let checksumLength = 2
    static private let ss58prefix = "SS58PRE".data(using: .utf8) ?? Data()
    
    init?(string: String, network: PolkadotNetwork) {
        guard Self.isValid(string, in: network) else {
            return nil
        }
        self.string = string
    }
    
    init(publicKey: Data, network: PolkadotNetwork) {
        var addressData = Data()
        
        addressData.append(network.addressPrefix)
        addressData.append(publicKey)
        
        let checksumMessage = Self.ss58prefix + addressData
        let checksum = Self.blake2checksum(checksumMessage)
        addressData.append(checksum)
                
        self.string = String(base58: addressData, alphabet: Base58String.btcAlphabet)
    }
    
    // Raw representation (without the prefix) was used in the older protocol versions
    func bytes(addNullPrefix: Bool) -> Data? {
        guard var bytes = string.base58DecodedData else {
            return nil
        }
        
        bytes.removeFirst(Self.networkLength)
        bytes.removeLast(Self.checksumLength)
        
        if addNullPrefix {
            bytes = Data(UInt8(0)) + bytes
        }
        
        return bytes
    }
    
    static private func isValid(_ address: String, in network: PolkadotNetwork) -> Bool {
        guard let data = address.base58DecodedData else {
            return false
        }
        
        let networkPrefix = data.prefix(networkLength)
        guard networkPrefix == network.addressPrefix else {
            return false
        }
        
        let expectedChecksum = data.suffix(checksumLength)
        let addressData = data.dropLast(checksumLength)
        
        let checksumMessage = ss58prefix + addressData
        let checksum = blake2checksum(checksumMessage)
        
        return checksum == expectedChecksum
    }

    static private func blake2checksum(_ message: Data) -> Data {
        let hash = Data(Sodium().genericHash.hash(message: message.bytes, outputLength: 64) ?? [])
        let checksum = hash.prefix(checksumLength)
        return checksum
    }
}
