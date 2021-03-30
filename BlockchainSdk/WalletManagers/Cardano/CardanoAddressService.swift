//
//  CardanoAddressService.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 08.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import SwiftCBOR
import CryptoSwift

protocol CardanoAddressDecoder {
    func decode(_ address: String) -> Data?
}

public class CardanoAddressService: AddressService, CardanoAddressDecoder {
    private let addressHeaderByte = Data([UInt8(97)])
    private let bech32Hrp = "addr"
    private let bech32Separator = "1"
    
    private var bech32Prefix: String { bech32Hrp + bech32Separator }
    
    private let shelley: Bool
    
    public init(shelley: Bool) {
        self.shelley = shelley
    }
    
    public func makeAddresses(from walletPublicKey: Data) -> [Address] {
        if shelley {
            return [
                PlainAddress(value: makeByronAddress(from: walletPublicKey)),
                PlainAddress(value: makeShelleyAddress(from: walletPublicKey))
            ]
        }
        return [PlainAddress(value: makeAddress(from: walletPublicKey))]
    }
    
    public func makeAddress(from walletPublicKey: Data) -> String {
        shelley ?
            makeShelleyAddress(from: walletPublicKey) :
            makeByronAddress(from: walletPublicKey)
    }
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty else {
            return false
        }
        
        if isBech32Address(address) {
            return (try? Bech32().decodeLong(address)) != nil
            
        } else {
            guard let decoded58 = address.base58DecodedData?.bytes,
                decoded58.count > 0 else {
                    return false
            }
            
            guard let cborArray = try? CBORDecoder(input: decoded58).decodeItem(),
                let addressArray = cborArray[0],
                let checkSumArray = cborArray[1] else {
                    return false
            }
            
            guard case let CBOR.tagged(_, cborByteString) = addressArray,
                case let CBOR.byteString(addressBytes) = cborByteString else {
                    return false
            }
            
            guard case let CBOR.unsignedInt(checksum) = checkSumArray else {
                return false
            }
            
            let calculatedChecksum = UInt64(addressBytes.crc32())
            return calculatedChecksum == checksum
        }
    }
    
    public func decode(_ address: String) -> Data? {
        guard isBech32Address(address) else {
            return address.base58DecodedData
        }
        
        let bech32 = Bech32()
        guard let decoded = try? bech32.decodeLong(address) else {
            return nil
        }
        
        guard let converted = try? bech32.convertBits(data: Array(decoded.checksum), fromBits: 5, toBits: 8, pad: false) else {
            return nil
        }
        
        return Data(converted)
    }
    
    private func isBech32Address(_ address: String) -> Bool {
        address.starts(with: bech32Prefix)
    }
    
    private func makeByronAddress(from walletPublicKey: Data) -> String {
        let hexPublicKeyExtended = walletPublicKey + Data(repeating: 0, count: 32) // extendedPublicKey
        let forSha3 = ([0, [0, CBOR.byteString(hexPublicKeyExtended.toBytes)], [:]] as CBOR).encode() // makePubKeyWithAttributes
        let sha = forSha3.sha3(.sha256)
        let pkHash = Sodium().genericHash.hash(message: sha, outputLength: 28)! // calculate blake 2b
        let addr = ([CBOR.byteString(pkHash), [:], 0] as CBOR).encode() // makeHashWithAttributes
        let checksum = UInt64(addr.crc32()) // getCheckSum
        let addrItem = CBOR.tagged(CBOR.Tag(rawValue: 24), CBOR.byteString(addr))
        let hexAddress = ([addrItem, CBOR.unsignedInt(checksum)] as CBOR).encode()
        let walletAddress = String(base58: Data(hexAddress), alphabet: Base58String.btcAlphabet)
        return walletAddress
    }
    
    private func makeShelleyAddress(from walletPublicKey: Data) -> String {
        let publicKeyHash = Sodium().genericHash.hash(message: walletPublicKey.toBytes, outputLength: 28)!
        let addressBytes = addressHeaderByte + publicKeyHash
        let bech32 = Bech32()
        let walletAddress = bech32.encode(bech32Hrp, values: Data(addressBytes))
        return walletAddress
    }
}
