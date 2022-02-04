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

class AddressesTests: XCTestCase {
    private let secpPrivKey = Data(hexString: "83686EF30173D2A05FD7E2C8CB30941534376013B903A2122CF4FF3E8668355A")
    private let secpDecompressedKey = Data(hexString: "0441DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45E3D67E8D2947E6FEE8B62D3D3B6A4D5F212DA23E478DD69A2C6CCC851F300D80")
    private let secpCompressedKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private let edKey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")
  
    func testBtc() {
        let blockchain = Blockchain.bitcoin(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
//        let addr3 = btc.makeAddresses(from: edKey, with: nil)
//        XCTAssertEqual(addr3.count, 0) //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        let bech32_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .bech32)})!
        let bech32_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .bech32)})!
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "bc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5edc40am")
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        
        let leg_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .legacy) })!
        let leg_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .legacy) })!
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "1HTBz4DRWpDET1QNMqsWKJ39WyWcwPWexK")
        XCTAssertEqual(leg_comp.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ")
    }
    
    func testBtcTestnet() {
        let blockchain = Blockchain.bitcoin(testnet: true)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        
//        let addr3 = btc.makeAddresses(from: edKey, with: nil)
//        XCTAssertEqual(addr3.count, 0) //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        let bech32_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .bech32)})!
        let bech32_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .bech32)})!
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        XCTAssertEqual(bech32_dec.value, "tb1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5e87wuxg") //todo: validate with android
        
        let leg_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .legacy) })!
        let leg_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .legacy) })!
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
        
    
        XCTAssertEqual(addr_dec.first(where: {$0.type == .bitcoin(type: .bech32)})!.value, "bc1q0u3heda6uhq7fulsqmw40heuh3e76nd9skxngv93uzz3z6xtpjmsrh88wh")
        XCTAssertEqual(addr_dec.first(where: {$0.type == .bitcoin(type: .legacy)})!.value, "34DmpSKfsvqxgzVVhcEepeX3s67ai4ShPq")
        
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
        
//        let addr3 = btc.makeAddresses(from: edKey, with: nil)
//        XCTAssertEqual(addr3.count, 0) //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addr_dec.count, 2)
        XCTAssertEqual(addr_comp.count, 2)
        
        let bech32_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .bech32)})!
        let bech32_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .bech32)})!
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "ltc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5efy0t9t") //todo: validate
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        
        let leg_dec = addr_dec.first(where: { $0.type == .bitcoin(type: .legacy) })!
        let leg_comp = addr_comp.first(where: { $0.type == .bitcoin(type: .legacy) })!
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "Lbg9FGXFbUTHhp6XXyrobK6ujBsu7UE7ww")
        XCTAssertEqual(leg_comp.value, "LcxUXkP9KGqWHtbKyENSS8HQoQ9LK8DQLX")
    }
    
    func testXlm() {
        let blockchain = Blockchain.stellar(testnet: false)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
       // XCTAssertThrowsError(blockchain.makeAddresses(from: secpCompressedKey, with: nil))
       //  XCTAssertThrowsError(blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
       //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, "")
        XCTAssertEqual(addrs[0].value, "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
    }
    
    func testXlmTestnet() {
        let blockchain = Blockchain.stellar(testnet: true)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
       // XCTAssertThrowsError(blockchain.makeAddresses(from: secpCompressedKey, with: nil))
       //  XCTAssertThrowsError(blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
       //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, "")
        XCTAssertEqual(addrs[0].value, "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
    }
    
    func testEth() {
        let blockchain = Blockchain.ethereum(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
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
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc") //we ignore uncompressed addresses
    }
    
    func testBchTestnet() {
        let blockchain = Blockchain.bitcoinCash(testnet: true)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc") //we ignore uncompressed addresses
    }
    
    func testBinance() {
        let blockchain = Blockchain.binance(testnet: false)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
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
        
       // XCTAssertThrowsError(blockchain.makeAddresses(from: secpCompressedKey, with: nil))
       //  XCTAssertThrowsError(blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
       //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, CardanoAddressType.legacy.localizedName)
        XCTAssertEqual(addrs[0].value, "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
    }
    
    func testAdaShelley() {
        let blockchain = Blockchain.cardano(shelley: true)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
       // XCTAssertThrowsError(blockchain.makeAddresses(from: secpCompressedKey, with: nil))
       //  XCTAssertThrowsError(blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
       //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addrs.count, 2)
        XCTAssertEqual(addrs[1].localizedName, CardanoAddressType.legacy.localizedName)
        XCTAssertEqual(addrs[1].value, "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
        
        XCTAssertEqual(addrs[0].localizedName, CardanoAddressType.bech32.localizedName)
        XCTAssertEqual(addrs[0].value, "addr1vyq5f2ntspszzu77guh8kg4gkhzerws5t9jd6gg4d222yfsajkfw5")
    }
    
    func testXrpSecp() {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].value, "rJjXGYnKNcbTsnuwoaP9wfDebB8hDX8jdQ")
    }
    
    func testXrpEd() {
        let blockchain = Blockchain.xrp(curve: .ed25519)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
       // XCTAssertThrowsError(blockchain.makeAddresses(from: secpCompressedKey, with: nil))
       //  XCTAssertThrowsError(blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
       //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, "")
        XCTAssertEqual(addrs[0].value, "rPhmKhkYoMiqC2xqHYhtPLnicWQi85uDf2") //todo: validate
    }
    
    func testDuc() {
        let blockchain = Blockchain.dogecoin
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
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
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].value, "tz2SdMQ72FP39GB1Cwyvs2BPRRAMv9M6Pc6B")
    }
    
    func testXTZEd() {
        let blockchain = Blockchain.tezos(curve: .ed25519)
        let addrs = try! blockchain.makeAddresses(from: edKey, with: nil)
        
       // XCTAssertThrowsError(blockchain.makeAddresses(from: secpCompressedKey, with: nil))
       //  XCTAssertThrowsError(blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
       //todo: uncomment after cryptoutils refactoring
        
        XCTAssertEqual(addrs.count, 1)
        XCTAssertEqual(addrs[0].localizedName, "")
        XCTAssertEqual(addrs[0].value, "tz1VS42nEFHoTayE44ZKANQWNhZ4QbWFV8qd")
    }
    
    func testDoge() {
        let blockchain = Blockchain.dogecoin
        let addr_dec = try! blockchain.makeAddresses(from: secpDecompressedKey, with: nil)
        let addr_comp = try! blockchain.makeAddresses(from: secpCompressedKey, with: nil)
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
        XCTAssertEqual(addr_dec.count, 1)
        XCTAssertEqual(addr_comp.count, 1)
        XCTAssertEqual(addr_dec[0].value, addr_comp[0].value)
        XCTAssertEqual(addr_dec[0].localizedName, addr_comp[0].localizedName)
        XCTAssertEqual(addr_dec[0].type, addr_comp[0].type)
        XCTAssertEqual(addr_dec[0].value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testPolkadot() {
        // From trust wallet `PolkadotTests.swift`
        testSubstrateNetwork(
            .polkadot,
            publicKey: Data(hexString: "53d82211c4aadb8c67e1930caef2058a93bc29d7af86bf587fba4aa3b1515037"),
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
        testSubstrateNetwork(
            .kusama,
            publicKey: Data(hexString: "e0b3fcccfe0283cc0f8c105c68b5690aab8c5c1692a868e55eaca836c8779085"),
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
        
        // TODO: uncomment and check the key in PolkadotAddressService
//        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpCompressedKey, with: nil))
//        XCTAssertThrowsError(try blockchain.makeAddresses(from: secpDecompressedKey, with: nil))
        
        XCTAssertEqual(addresses.count, 1)
        XCTAssertNotNil(addressFromString)
        XCTAssertEqual(addressFromString!.bytes(raw: true), publicKey)
        XCTAssertEqual(addresses.first!.value, expectedAddress)
        XCTAssertNotEqual(addressFromString!.bytes(raw: false), publicKey)
        XCTAssertFalse(otherNetworkAddresses.contains(addressFromString!.string))
    }
}
