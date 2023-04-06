//
//  AddressesTests.swift
//  BlockchainSdkTests
//
//  Created by Alexander Osokin on 29.12.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemSdk
import CryptoKit
import HDWalletKit

@testable import BlockchainSdk

class AddressesTests: XCTestCase {
    private let secpPrivKey = Data(hexString: "83686EF30173D2A05FD7E2C8CB30941534376013B903A2122CF4FF3E8668355A")
    private let secpDecompressedKey = Data(hexString: "0441DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45E3D67E8D2947E6FEE8B62D3D3B6A4D5F212DA23E478DD69A2C6CCC851F300D80")
    private let secpCompressedKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private let edKey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")

    func testBtc() {
        let blockchain = Blockchain.bitcoin(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        let bech32_dec = addr_dec.first(where: { $0.type == .default })!
        let bech32_comp = addr_comp.first(where: { $0.type == .default})!
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "bc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5edc40am")
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        
        let leg_dec = addr_dec.first(where: { $0.type == .legacy })!
        let leg_comp = addr_comp.first(where: { $0.type == .legacy })!
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "1HTBz4DRWpDET1QNMqsWKJ39WyWcwPWexK")
        XCTAssertEqual(leg_comp.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ")
    }
    
    func testBtcTestnet() {
        let blockchain = Blockchain.bitcoin(testnet: true)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        let bech32_dec = addr_dec.first(where: { $0.type == .default})!
        let bech32_comp = addr_comp.first(where: { $0.type == .default})!
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        XCTAssertEqual(bech32_dec.value, "tb1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5e87wuxg") //todo: validate with android
        
        let leg_dec = addr_dec.first(where: { $0.type == .legacy })!
        let leg_comp = addr_comp.first(where: { $0.type == .legacy })!
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "mwy9H7JQKqeVE7sz5Qqt9DFUNy7KtX7wHj") //todo: validate with android
        XCTAssertEqual(leg_comp.value, "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ") //todo: validate with android
    }
    
    func testBtcTwin() {
        // let secpPairPrivKey = Data(hexString: "997D79C06B72E8163D1B9FCE6DA0D2ABAA15B85E52C6032A087342BAD98E5316")
        let secpPairDecompressedKey = Data(hexString: "042A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D8936D318D49FE06E3437E31568B338B340F4E6DF5184E1EC5840F2B7F4596902AE")
        let secpPairCompressedKey = Data(hexString: "022A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D89")
        
        let blockchain = Blockchain.bitcoin(testnet: false) //no testnet for twins
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: secpPairDecompressedKey)
        let addr_dec1 = try! blockchain.makeAddresses(from: secpDecompressedKey, with: secpPairCompressedKey)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: secpPairCompressedKey)
        let addr_comp1 = try! blockchain.makeAddresses(from: secpCompressedKey, with: secpPairDecompressedKey)
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_dec1.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        XCTAssertEqual(addr_comp1.count, 2)
        

        XCTAssertEqual(addr_dec.first(where: {$0.type == .default})!.value, "bc1q0u3heda6uhq7fulsqmw40heuh3e76nd9skxngv93uzz3z6xtpjmsrh88wh")
        XCTAssertEqual(addr_dec.first(where: {$0.type == .legacy})!.value, "34DmpSKfsvqxgzVVhcEepeX3s67ai4ShPq")
        
        for index in 0..<2 {
            XCTAssertEqual(addr_dec[index].value, addr_dec1[index].value)
            XCTAssertEqual(addr_dec[index].value, addr_comp[index].value)
            XCTAssertEqual(addr_dec[index].value, addr_comp1[index].value)
            
            XCTAssertEqual(addr_dec[index].localizedName, addr_dec1[index].localizedName)
            XCTAssertEqual(addr_dec[index].localizedName, addr_comp[index].localizedName)
            XCTAssertEqual(addr_dec[index].localizedName, addr_comp1[index].localizedName)
            
            XCTAssertEqual(addr_dec[index].type, addr_dec1[index].type)
            XCTAssertEqual(addr_dec[index].type, addr_comp[index].type)
            XCTAssertEqual(addr_dec[index].type, addr_comp1[index].type)
        }
    }
    
    func testLtc() {
        let blockchain = Blockchain.litecoin
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        let bech32_dec = addr_dec.first(where: { $0.type == .default})!
        let bech32_comp = addr_comp.first(where: { $0.type == .default})!
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "ltc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5efy0t9t") //todo: validate
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        
        let leg_dec = addr_dec.first(where: { $0.type == .legacy })!
        let leg_comp = addr_comp.first(where: { $0.type == .legacy })!
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "Lbg9FGXFbUTHhp6XXyrobK6ujBsu7UE7ww")
        XCTAssertEqual(leg_comp.value, "LcxUXkP9KGqWHtbKyENSS8HQoQ9LK8DQLX")
    }
    
    func testXlm() {
        let blockchain = Blockchain.stellar(testnet: false)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs[0].value, "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
    }
    
    func testXlmTestnet() {
        let blockchain = Blockchain.stellar(testnet: true)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs[0].value, "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
    }
    
    func testEth() {
        let blockchain = Blockchain.ethereum(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testEthTestnet() {
        let blockchain = Blockchain.ethereum(testnet: true)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testRsk() {
        let blockchain = Blockchain.rsk
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "0x6ECA00c52afC728CDbf42E817d712E175Bb23C7d")
    }
    
    func testBch() {
        let blockchain = Blockchain.bitcoinCash(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        for index in 0..<2 {
            XCTAssertEqual(addr_dec[index].value, addr_comp[index].value)
            XCTAssertEqual(addr_dec[index].localizedName, addr_comp[index].localizedName)
            XCTAssertEqual(addr_dec[index].type, addr_comp[index].type)
        }
        
        let testRemovePrefix = String("bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc".removeBchPrefix())
        XCTAssertEqual(testRemovePrefix, "qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc")
        
        XCTAssertEqual(addr_comp[0].value, "bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc") //we ignore uncompressed addresses
        XCTAssertEqual(addr_comp[1].value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ") //we ignore uncompressed addresses
    }
    
    func testBchTestnet() {
        let blockchain = Blockchain.bitcoinCash(testnet: true)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        for index in 0..<2 {
            XCTAssertEqual(addr_dec[index].value, addr_comp[index].value)
            XCTAssertEqual(addr_dec[index].localizedName, addr_comp[index].localizedName)
            XCTAssertEqual(addr_dec[index].type, addr_comp[index].type)
        }
        
        XCTAssertEqual(addr_comp[0].value, "bchtest:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyzjtuac9y") //we ignore uncompressed addresses
        XCTAssertEqual(addr_comp[1].value, "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ") //we ignore uncompressed addresses
    }
    
    func testBinance() {
        let blockchain = Blockchain.binance(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "bnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eex5gcc")
    }
    
    func testBinanceTestnet() {
        let blockchain = Blockchain.binance(testnet: true)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "tbnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5ehnavcf") //todo: validate
    }
    
    func testAda() {
        let blockchain = Blockchain.cardano(shelley: false)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, AddressType.legacy.defaultLocalizedName)
        XCTAssertEqual(addrs[0].value, "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
    }
    
    func testAdaShelley() {
        let blockchain = Blockchain.cardano(shelley: true)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addrs.count, 2)
        XCTAssertEqual(addrs[1].localizedName, AddressType.legacy.defaultLocalizedName)
        XCTAssertEqual(addrs[1].value, "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
        
        XCTAssertEqual(addrs[0].localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs[0].value, "addr1vyq5f2ntspszzu77guh8kg4gkhzerws5t9jd6gg4d222yfsajkfw5")
    }
    
    func testXrpSecp() {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)

        for address in addr_dec {
            XCTAssertEqual(blockchain.validate(address: address.value), true)
        }

        for address in addr_comp {
            XCTAssertEqual(blockchain.validate(address: address.value), true)
        }

        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].value, "rJjXGYnKNcbTsnuwoaP9wfDebB8hDX8jdQ")
    }
    
    func testXrpEd() {
        let blockchain = Blockchain.xrp(curve: .ed25519)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)

        for address in addrs {
            XCTAssertEqual(blockchain.validate(address: address.value), true)
        }

        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs[0].value, "rPhmKhkYoMiqC2xqHYhtPLnicWQi85uDf2") //todo: validate
    }
    
    func testDuc() {
        let blockchain = Blockchain.dogecoin
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, "DMbHXKA4pE7Wz1ay6Rs4s4CkQ7EvKG3DqY")
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_comp[0].value, "DNscoo1xY2Vja65mXgNhhsPFUKWMa7NLEb")
    }
    
    func testXTZSecp() {
        let blockchain = Blockchain.tezos(curve: .secp256k1)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].value, "tz2SdMQ72FP39GB1Cwyvs2BPRRAMv9M6Pc6B")
    }
    
    func testXTZEd() {
        let blockchain = Blockchain.tezos(curve: .ed25519)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs[0].value, "tz1VS42nEFHoTayE44ZKANQWNhZ4QbWFV8qd")
    }
    
    func testDoge() {
        let blockchain = Blockchain.dogecoin
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, "DMbHXKA4pE7Wz1ay6Rs4s4CkQ7EvKG3DqY")
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_comp[0].value, "DNscoo1xY2Vja65mXgNhhsPFUKWMa7NLEb")
    }
    
    func testBsc() {
        let blockchain = Blockchain.bsc(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testBscTestnet() {
        let blockchain = Blockchain.bsc(testnet: true)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testPolygon() {
        let blockchain = Blockchain.polygon(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testPolygonTestnet() {
        let blockchain = Blockchain.polygon(testnet: true)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: edKey, with: nil))
        
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testSolana() {
        let key = Data(hexString: "0300000000000000000000000000000000000000000000000000000000000000")
        let blockchain = Blockchain.solana(testnet: false)
        let blockchain1 = Blockchain.solana(testnet: true)
        let addrs = try! blockchain.makeAddresses(from: key, with: nil)
        let addrs1 = try! blockchain1.makeAddresses(from: key, with: nil)

        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs1.count, 1)
        XCTAssertEqual(addrs[0].value, addrs1[0].value)
        XCTAssertEqual(addrs[0].localizedName, addrs1[0].localizedName)
        XCTAssertEqual(addrs[0].type, addrs1[0].type)
        XCTAssertEqual(addrs[0].value, "CiDwVBFgWV9E5MvXWoLgnEgn2hK7rJikbvfWavzAQz3")
        
        let addrFromTangemKey = try! blockchain.makeAddresses(from: edKey, with: nil).first!
        XCTAssertEqual(addrFromTangemKey.value, "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ")
    }
    
    func testPolkadot() {
        // From trust wallet `PolkadotTests.swift`
        let privateKey = Data(hexString: "0xd65ed4c1a742699b2e20c0c1f1fe780878b1b9f7d387f934fe0a7dc36f1f9008")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        testSubstrateNetwork(
            .polkadot,
            publicKey: publicKey,
            expectedAddress: "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW"
        )
        
        testSubstrateNetwork(
            .polkadot,
            publicKey: edKey,
            expectedAddress: "14cermZiQ83ihmHKkAucgBT2sqiRVvd4rwqBGqrMnowAKYRp"
        )
    }
    
    func testKusama() {
        // From trust wallet `KusamaTests.swift`
        let privateKey = Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        testSubstrateNetwork(
            .kusama,
            publicKey: publicKey,
            expectedAddress: "HewiDTQv92L2bVtkziZC8ASxrFUxr6ajQ62RXAnwQ8FDVmg"
        )
        
        testSubstrateNetwork(
            .kusama,
            publicKey: edKey,
            expectedAddress: "GByNkeXAhoB1t6FZEffRyytAp11cHt7EpwSWD8xiX88tLdQ"
        )
    }
    
    func testWestend() {
        testSubstrateNetwork(
            .westend,
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }
    
    func testSubstrateNetwork(_ network: PolkadotNetwork, publicKey: Data, expectedAddress: String) {
        let otherNetworks = PolkadotNetwork.allCases.filter { $0 != network }
        let blockchain = network.blockchain
        
        let addresses = try! blockchain.makeAddresses(from: publicKey, with: nil)
        let addressFromString = PolkadotAddress(string: expectedAddress, network: network)
        
        let otherNetworkAddresses = otherNetworks.map {
            try! $0.blockchain.makeAddresses(from: publicKey, with: nil).first!.value
        }
        
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addresses.count, 1)
        XCTAssertNotNil(addressFromString)
        XCTAssertEqual(addressFromString!.bytes(raw: true), publicKey)
        XCTAssertEqual(addresses.first!.value, expectedAddress)
        XCTAssertNotEqual(addressFromString!.bytes(raw: false), publicKey)
        XCTAssertFalse(otherNetworkAddresses.contains(addressFromString!.string))
    }
    
    func testTron() {
        // From https://developers.tron.network/docs/account
        let publicKey1 = Data(hexString: "0404B604296010A55D40000B798EE8454ECCC1F8900E70B1ADF47C9887625D8BAE3866351A6FA0B5370623268410D33D345F63344121455849C9C28F9389ED9731")
        let address1 = try! TronAddressService().makeAddress(from: publicKey1)
        XCTAssertTrue(address1 == "TDpBe64DqirkKWj6HWuR1pWgmnhw2wDacE")
        
        
        let compressedKeyAddress = try! TronAddressService().makeAddress(from: secpCompressedKey)
        XCTAssertTrue(compressedKeyAddress == "TL51KaL2EPoAnPLgnzdZndaTLEbd1P5UzV")
        
        let decompressedKeyAddress = try! TronAddressService().makeAddress(from: secpDecompressedKey)
        XCTAssertTrue(decompressedKeyAddress == "TL51KaL2EPoAnPLgnzdZndaTLEbd1P5UzV")
        
        XCTAssertTrue (TronAddressService().validate("TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"))
        XCTAssertFalse(TronAddressService().validate("RJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"))
    }
    
    // MARK: - Dash addresses

    func testDashCompressedMainnet() {
        // given
        let blockchain = Blockchain.dash(testnet: false)
        let addressService = blockchain.getAddressService()
        let expectedAddress = "XtRN6njDCKp3C2VkeyhN1duSRXMkHPGLgH"
        
        // when
        do {
            let address = try addressService.makeAddress(from: secpCompressedKey)
            
            XCTAssertEqual(address, expectedAddress)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testDashDecompressedMainnet() {
        // given
        let blockchain = Blockchain.dash(testnet: false)
        let addressService = blockchain.getAddressService()
        let expectedAddress = "Xs92pJsKUXRpbwzxDjBjApiwMK6JysNntG"

        // when
        do {
            let address = try addressService.makeAddress(from: secpDecompressedKey)
            
            XCTAssertEqual(address, expectedAddress)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testDashTestnet() {
        // given
        let blockchain = Blockchain.dash(testnet: true)
        let addressService = blockchain.getAddressService()
        let expectedAddress = "yMfdoASh4QEM3zVpZqgXJ8St38X7VWnzp7"
        let compressedKey = Data(
            hexString: "021DCF0C1E183089515DF8C86DACE6DA08DC8E1232EA694388E49C3C66EB79A418"
        )
        
        // when
        do {
            let address = try addressService.makeAddress(from: compressedKey)
            
            XCTAssertEqual(address, expectedAddress)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testTON() {
        let blockchain = Blockchain.ton(testnet: false)
        let addressService = blockchain.getAddressService()
        
        let walletPubkey1 = Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb")
        let expectedAddress1 = "EQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrYeu"
        XCTAssertEqual(try! addressService.makeAddress(from: walletPubkey1), expectedAddress1)
        
        let walletPubkey2 = Data(hex: "258A89B60CCE7EB3339BF4DB8A8DA8153AA2B6489D22CC594E50FDF626DA7AF5")
        let expectedAddress2 = "EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"
        XCTAssertEqual(try! addressService.makeAddress(from: walletPubkey2), expectedAddress2)
        
        let walletPubkey3 = Data(hex: "f42c77f931bea20ec5d0150731276bbb2e2860947661245b2319ef8133ee8d41")
        let expectedAddress3 = "EQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts90Q"
        XCTAssertEqual(try! addressService.makeAddress(from: walletPubkey3), expectedAddress3)
        
        let walletPubkey4 = Data(hexString: "0404B604296010A55D40000B798EE8454ECCC1F8900E70B1ADF47C9887625D8BAE3866351A6FA0B5370623268410D33D345F63344121455849C9C28F9389ED9731")
        XCTAssertNil(try? addressService.makeAddress(from: walletPubkey4))
        
        let walletPubkey5 = Data(hexString: "042A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D8936D318D49FE06E3437E31568B338B340F4E6DF5184E1EC5840F2B7F4596902AE")
        XCTAssertNil(try? addressService.makeAddress(from: walletPubkey5))
        
        XCTAssertNil(try? addressService.makeAddress(from: secpCompressedKey))
        XCTAssertNil(try? addressService.makeAddress(from: secpDecompressedKey))
    }
    
    func testTONValidateCorrectAddress() {
        let blockchain = Blockchain.ton(testnet: false)
        let addressService = blockchain.getAddressService()
        
        XCTAssertTrue(addressService.validate("EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"))
        XCTAssertTrue(addressService.validate("EQAGDzFFIxJswaBU5Rqaz5H5dKUBGYEMhL44fpLtIdWbjkBo"))
        XCTAssertTrue(addressService.validate("EQA0i8-CdGnF_DhUHHf92R1ONH6sIA9vLZ_WLcCIhfBBXwtG"))
        XCTAssertTrue(addressService.validate("0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"))
        XCTAssertTrue(addressService.validate("0:66fbe3c5c03bf5c82792f904c9f8bf28894a6aa3d213d41c20569b654aadedb3"))
        XCTAssertFalse(addressService.validate("8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"))
    }
    
    func testKaspaAddressGeneration() {
        let blockchain = Blockchain.kaspa
        let addressService = blockchain.getAddressService()
        
        let expectedAddress = "kaspa:qypyrhxkfd055qulcvu6zccq4qe63qajrzgf7t4u4uusveguw6zzc3grrceeuex"
        XCTAssertEqual(try addressService.makeAddress(from: secpCompressedKey), expectedAddress)
        XCTAssertEqual(try addressService.makeAddress(from: secpDecompressedKey), expectedAddress)
        
        // https://github.com/kaspanet/kaspad/pull/2202/files
        // https://github.com/kaspanet/kaspad/blob/dev/util/address_test.go
        let kaspaTestPublicKey = Data([
            0x02, 0xf1, 0xd3, 0x78, 0x05, 0x46, 0xda, 0x20, 0x72, 0x8e, 0xa8, 0xa1, 0xf5, 0xe5, 0xe5, 0x1b, 0x84, 0x38, 0x00, 0x2c, 0xd7, 0xc8, 0x38, 0x2a, 0xaf, 0xa7, 0xdd, 0xf6, 0x80, 0xe1, 0x25, 0x57, 0xe4,
        ])
        let kaspaTestAddress = "kaspa:qyp0r5mcq4rd5grj3652ra09u5dcgwqq9ntuswp247nama5quyj40eq03sc2dkx"
        XCTAssertEqual(try addressService.makeAddress(from: kaspaTestPublicKey), kaspaTestAddress)
        
        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }
    
    func testKaspaAddressComponentsAndValidation() {
        let blockchain = Blockchain.kaspa
        let addressService = blockchain.getAddressService() as! KaspaAddressService
        
        XCTAssertFalse(addressService.validate("kaspb:qyp5ez9p4q6xnh0jp5xq0ewy58nmsde5uus7vrty9w222v3zc37xwrgeqhkq7v3"))
        XCTAssertFalse(addressService.validate("kaspa:qyp5ez9p4q6xnh0jp5xq0ewy58nmsde5uus7vrty9w222v3zc37xwrgeqhkq7v4"))
        
        let ecdsaAddress = "kaspa:qyp4scvsxvkrjxyq98gd4xedhgrqtmf78l7wl8p8p4j0mjuvpwjg5cqhy97n472"
        let ecdsaAddressComponents = addressService.parse(ecdsaAddress)!
        XCTAssertTrue(addressService.validate(ecdsaAddress))
        XCTAssertEqual(ecdsaAddressComponents.hash, Data(hex: "03586190332c39188029d0da9b2dba0605ed3e3ffcef9c270d64fdcb8c0ba48a60"))
        XCTAssertEqual(ecdsaAddressComponents.type, .P2PK_ECDSA)
        
        let schnorrAddress = "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv"
        let schnorrAddressComponents = addressService.parse(schnorrAddress)!
        XCTAssertTrue(addressService.validate(schnorrAddress))
        XCTAssertEqual(schnorrAddressComponents.hash, Data(hex: "60072BBDDB7A7D1DBF40302CE04D51DB49E223F8E5159FCCE14143FD4BE20328"))
        XCTAssertEqual(schnorrAddressComponents.type, .P2PK_Schnorr)
        
        let p2shAddress = "kaspa:pqurku73qluhxrmvyj799yeyptpmsflpnc8pha80z6zjh6efwg3v2rrepjm5r"
        let p2shAddressComponents = addressService.parse(p2shAddress)!
        XCTAssertTrue(addressService.validate(p2shAddress))
        XCTAssertEqual(p2shAddressComponents.hash, Data(hex: "383b73d107f9730f6c24bc5293240ac3b827e19e0e1bf4ef16852beb297222c5"))
        XCTAssertEqual(p2shAddressComponents.type, .P2SH)
    }
    
    func testRavencoinCompressedMainNet() {
         let blockchain = Blockchain.ravencoin(testnet: false)
         let addressService = blockchain.getAddressService()
         let expectedAddress = "RT1iM3xbqSQ276GNGGNGFdYrMTEeq4hXRH"

         // when
         do {
             let address = try addressService.makeAddress(from: secpCompressedKey)

             XCTAssertEqual(address, expectedAddress)
         } catch {
             XCTAssertNil(error)
         }
     }

     func testRavencoinDecompressedMainNet() {
         let blockchain = Blockchain.ravencoin(testnet: false)
         let addressService = blockchain.getAddressService()
         // https://ravencoin.network/api/addr/RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi/balance
         let expectedAddress = "RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi"

         // when
         do {
             let address = try addressService.makeAddress(from: secpDecompressedKey)

             XCTAssertEqual(address, expectedAddress)
         } catch {
             XCTAssertNil(error)
         }
     }
}
