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
import BitcoinCore

@testable import BlockchainSdk

class AddressesTests: XCTestCase {
    private let secpPrivKey = Data(hexString: "83686EF30173D2A05FD7E2C8CB30941534376013B903A2122CF4FF3E8668355A")
    private let secpDecompressedKey = Data(hexString: "0441DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45E3D67E8D2947E6FEE8B62D3D3B6A4D5F212DA23E478DD69A2C6CCC851F300D80")
    private let secpCompressedKey = Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45")
    private let edKey = Data(hex: "9FE5BB2CC7D83C1DA10845AFD8A34B141FD8FD72500B95B1547E12B9BB8AAC3D")
    
    let addressesUtility = AddressServiceManagerUtility()
    
    func testBtc() throws {
        let blockchain = Blockchain.bitcoin(testnet: false)
        let service = BitcoinAddressService(networkParams: BitcoinNetwork.mainnet.networkParams)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))
        
        let bech32_dec = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let bech32_comp = try service.makeAddress(from: secpCompressedKey, type: .default)
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "bc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5edc40am")
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), bech32_dec.value)
        
        let leg_dec = try service.makeAddress(from: secpDecompressedKey, type: .legacy)
        let leg_comp = try service.makeAddress(from: secpCompressedKey, type: .legacy)
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "1HTBz4DRWpDET1QNMqsWKJ39WyWcwPWexK")
        XCTAssertEqual(leg_comp.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ")
    }
    
    func testBtcTestnet() throws {
        let service = BitcoinAddressService(networkParams: BitcoinNetwork.testnet.networkParams)
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        let bech32_dec = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let bech32_comp = try service.makeAddress(from: secpCompressedKey, type: .default)
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        XCTAssertEqual(bech32_dec.value, "tb1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5e87wuxg") //todo: validate with android
        
        let leg_dec = try service.makeAddress(from: secpDecompressedKey, type: .legacy)
        let leg_comp = try service.makeAddress(from: secpCompressedKey, type: .legacy)
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "mwy9H7JQKqeVE7sz5Qqt9DFUNy7KtX7wHj") //todo: validate with android
        XCTAssertEqual(leg_comp.value, "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ") //todo: validate with android
    }
    
    func testBtcTwin() throws {
        // let secpPairPrivKey = Data(hexString: "997D79C06B72E8163D1B9FCE6DA0D2ABAA15B85E52C6032A087342BAD98E5316")
        let secpPairDecompressedKey = Data(hexString: "042A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D8936D318D49FE06E3437E31568B338B340F4E6DF5184E1EC5840F2B7F4596902AE")
        let secpPairCompressedKey = Data(hexString: "022A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D89")
        let service = BitcoinAddressService(networkParams: BitcoinNetwork.mainnet.networkParams)

        let addr_dec = try service.makeAddresses(publicKey: .init(seedKey: secpDecompressedKey, derivation: .none),
                                                 pairPublicKey: secpPairDecompressedKey)
        let addr_dec1 = try service.makeAddresses(publicKey: .init(seedKey: secpDecompressedKey, derivation: .none),
                                                  pairPublicKey: secpPairCompressedKey)
        let addr_comp = try service.makeAddresses(publicKey: .init(seedKey: secpCompressedKey, derivation: .none),
                                                  pairPublicKey: secpPairCompressedKey)
        let addr_comp1 = try service.makeAddresses(publicKey: .init(seedKey: secpCompressedKey, derivation: .none),
                                                   pairPublicKey: secpPairDecompressedKey)
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
    
    func testLtc() throws {
        let blockchain = Blockchain.litecoin
        let service = BitcoinAddressService(networkParams: LitecoinNetworkParams())

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        let bech32_dec = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let bech32_comp = try service.makeAddress(from: secpCompressedKey, type: .default)
        XCTAssertEqual(bech32_dec.value, bech32_comp.value)
        XCTAssertEqual(bech32_dec.value, "ltc1qc2zwqqucrqvvtyxfn78ajm8w2sgyjf5efy0t9t") //todo: validate
        XCTAssertEqual(bech32_dec.localizedName, bech32_comp.localizedName)
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), bech32_dec.value)
        
        let leg_dec = try service.makeAddress(from: secpDecompressedKey, type: .legacy)
        let leg_comp = try service.makeAddress(from: secpCompressedKey, type: .legacy)
        XCTAssertEqual(leg_dec.localizedName, leg_comp.localizedName)
        XCTAssertEqual(leg_dec.value, "Lbg9FGXFbUTHhp6XXyrobK6ujBsu7UE7ww")
        XCTAssertEqual(leg_comp.value, "LcxUXkP9KGqWHtbKyENSS8HQoQ9LK8DQLX")
    }
    
    func testXlm() throws {
        let blockchain = Blockchain.stellar(testnet: false)
        let service = StellarAddressService()

        let addrs = try service.makeAddress(from: edKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs.value, "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: edKey, for: blockchain), "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
        
        let addr = try? AddressServiceManagerUtility().makeTrustWalletAddress(publicKey: edKey, for: blockchain)
        XCTAssertEqual(addrs.value, addr)
    }
    
    func testXlmTestnet() throws {
        let service = StellarAddressService()

        let addrs = try service.makeAddress(from: edKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs.value, "GCP6LOZMY7MDYHNBBBC27WFDJMKB7WH5OJIAXFNRKR7BFON3RKWD3XYA")
    }
    
    func testEth() throws {
        let blockchain = Blockchain.ethereum(testnet: false)
        let service = EthereumAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_dec.value)
    }
    
    func testEthTestnet() throws {
        let service = EthereumAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testRsk() throws {
        let service = RskAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECA00c52afC728CDbf42E817d712E175Bb23C7d")
    }
    
    func testBch() throws {
        let blockchain = Blockchain.bitcoinCash(testnet: false)
        let service = BitcoinCashAddressService(networkParams: BitcoinCashNetworkParams())

        let addr_dec_default = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let addr_dec_legacy = try service.makeAddress(from: secpDecompressedKey, type: .legacy)

        let addr_comp_default = try service.makeAddress(from: secpCompressedKey, type: .default)
        let addr_comp_legacy = try service.makeAddress(from: secpCompressedKey, type: .legacy)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))
        
        XCTAssertEqual(addr_dec_default.value, addr_comp_default.value)
        XCTAssertEqual(addr_dec_legacy.value, addr_comp_legacy.value)

        XCTAssertEqual(addr_dec_default.localizedName, addr_comp_default.localizedName)
        XCTAssertEqual(addr_dec_legacy.localizedName, addr_comp_legacy.localizedName)

        XCTAssertEqual(addr_dec_default.type, addr_comp_default.type)
        XCTAssertEqual(addr_dec_legacy.type, addr_comp_legacy.type)
        
        let testRemovePrefix = String("bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc".removeBchPrefix())
        XCTAssertEqual(testRemovePrefix, "qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc")
        
        XCTAssertEqual(addr_comp_default.value, "bitcoincash:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyxq0ml0zc") //we ignore uncompressed addresses
        XCTAssertEqual(addr_comp_legacy.value, "1JjXGY5KEcbT35uAo6P9A7DebBn4DXnjdQ") //we ignore uncompressed addresses
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp_default.value)
    }
    
    func testBchTestnet() throws {
        let service = BitcoinCashAddressService(networkParams: BitcoinCashTestNetworkParams())

        let addr_dec_default = try service.makeAddress(from: secpDecompressedKey, type: .default)
        let addr_dec_legacy = try service.makeAddress(from: secpDecompressedKey, type: .legacy)

        let addr_comp_default = try service.makeAddress(from: secpCompressedKey, type: .default)
        let addr_comp_legacy = try service.makeAddress(from: secpCompressedKey, type: .legacy)

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec_default.value, addr_comp_default.value)
        XCTAssertEqual(addr_dec_legacy.value, addr_comp_legacy.value)

        XCTAssertEqual(addr_dec_default.localizedName, addr_comp_default.localizedName)
        XCTAssertEqual(addr_dec_legacy.localizedName, addr_comp_legacy.localizedName)

        XCTAssertEqual(addr_dec_default.type, addr_comp_default.type)
        XCTAssertEqual(addr_dec_legacy.type, addr_comp_legacy.type)
        
        XCTAssertEqual(addr_comp_default.value, "bchtest:qrpgfcqrnqvp33vsex0clktvae2pqjfxnyzjtuac9y") //we ignore uncompressed addresses
        XCTAssertEqual(addr_comp_legacy.value, "myFUZbAJ3e2hpCNnWfMWz2RyTBNm7vdnSQ") //we ignore uncompressed addresses
    }
    
    func testBinance() throws {
        let blockchain = Blockchain.binance(testnet: false)
        let service = BinanceAddressService(testnet: false)

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "bnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eex5gcc")
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_dec.value)
    }
    
    func testBinanceTestnet() throws {
        let blockchain = Blockchain.binance(testnet: true)
        let service = BinanceAddressService(testnet: true)

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "tbnb1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5ehnavcf") //todo: validate
    }
    
    func testAda() throws {
        let service = CardanoAddressService(shelley: false)

        let addrs = try service.makeAddress(from: edKey, type: .legacy)
        
        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs.localizedName, AddressType.legacy.defaultLocalizedName)
        XCTAssertEqual(addrs.value, "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
    }
    
    func testAdaShelley() throws {
        let service = CardanoAddressService(shelley: true)

        let addrs_shelley = try service.makeAddress(from: edKey, type: .default) // default is shelley
        let addrs_byron = try service.makeAddress(from: edKey, type: .legacy) // legacy is byron

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs_byron.localizedName, AddressType.legacy.defaultLocalizedName)
        XCTAssertEqual(addrs_byron.value, "Ae2tdPwUPEZAwboh4Qb8nzwQe6kmT5A3EmGKAKuS6Tcj8UkHy6BpQFnFnND")
        
        XCTAssertEqual(addrs_shelley.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(addrs_shelley.value, "addr1vyq5f2ntspszzu77guh8kg4gkhzerws5t9jd6gg4d222yfsajkfw5")
    }
    
    func testXrpSecp() throws {
        let blockchain = Blockchain.xrp(curve: .secp256k1)
        let service = XRPAddressService(curve: .secp256k1)

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)

        XCTAssertTrue(service.validate(addr_dec.value))
        XCTAssertTrue(service.validate(addr_comp.value))

        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.value, "rJjXGYnKNcbTsnuwoaP9wfDebB8hDX8jdQ")
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_dec.value)
    }
    
    func testXrpEd() throws {
        let service = XRPAddressService(curve: .ed25519)
        let address = try service.makeAddress(from: edKey)

        XCTAssertTrue(service.validate(address.value))

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(address.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(address.value, "rPhmKhkYoMiqC2xqHYhtPLnicWQi85uDf2") //todo: validate
    }
    
    func testDuc() throws {
        let blockchain = Blockchain.dogecoin
        let service = BitcoinLegacyAddressService(networkParams: DogecoinNetworkParams())

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, "DMbHXKA4pE7Wz1ay6Rs4s4CkQ7EvKG3DqY")
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_comp.value, "DNscoo1xY2Vja65mXgNhhsPFUKWMa7NLEb")
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp.value)
    }
    
    func testXTZSecp() throws {
        let service = TezosAddressService(curve: .secp256k1)

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.value, "tz2SdMQ72FP39GB1Cwyvs2BPRRAMv9M6Pc6B")
    }
    
    func testXTZEd() throws {
        let service = TezosAddressService(curve: .ed25519)
        let address = try service.makeAddress(from: edKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(address.localizedName, AddressType.default.defaultLocalizedName)
        XCTAssertEqual(address.value, "tz1VS42nEFHoTayE44ZKANQWNhZ4QbWFV8qd")
    }
    
    func testDoge() throws {
        let blockchain = Blockchain.dogecoin
        let service = BitcoinLegacyAddressService(networkParams: DogecoinNetworkParams())

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, "DMbHXKA4pE7Wz1ay6Rs4s4CkQ7EvKG3DqY")
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_comp.value, "DNscoo1xY2Vja65mXgNhhsPFUKWMa7NLEb")
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp.value)
    }
    
    func testBsc() throws {
        let blockchain = Blockchain.bsc(testnet: false)
        let service = EthereumAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp.value)
    }
    
    func testBscTestnet() throws {
        let service = EthereumAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))
        

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
    }
    
    func testPolygon() throws {
        let blockchain = Blockchain.polygon(testnet: false)
        let service = EthereumAddressService()

        let addr_dec = try service.makeAddress(from: secpDecompressedKey)
        let addr_comp = try service.makeAddress(from: secpCompressedKey)
        
        XCTAssertThrowsError(try service.makeAddress(from: edKey))

        XCTAssertEqual(addr_dec.value, addr_comp.value)
        XCTAssertEqual(addr_dec.localizedName, addr_comp.localizedName)
        XCTAssertEqual(addr_dec.type, addr_comp.type)
        XCTAssertEqual(addr_dec.value, "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d")
        XCTAssertEqual("0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d".lowercased(), "0x6eca00c52afc728cdbf42e817d712e175bb23c7d") //without checksum
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpDecompressedKey, for: blockchain), addr_comp.value)
    }
    
    func testSolana() throws {
        let key = Data(hexString: "0300000000000000000000000000000000000000000000000000000000000000")
        let blockchain = Blockchain.solana(testnet: false)
        let service = SolanaAddressService()

        let addrs = try service.makeAddress(from: key)

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertEqual(addrs.value, "CiDwVBFgWV9E5MvXWoLgnEgn2hK7rJikbvfWavzAQz3")
        
        let addrFromTangemKey = try service.makeAddress(from: edKey)
        XCTAssertEqual(addrFromTangemKey.value, "BmAzxn8WLYU3gEw79ATUdSUkMT53MeS5LjapBQB8gTPJ")
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: edKey, for: blockchain), addrFromTangemKey.value)
    }
    
    func testPolkadot() throws {
        // From trust wallet `PolkadotTests.swift`
        let privateKey = Data(hexString: "0xd65ed4c1a742699b2e20c0c1f1fe780878b1b9f7d387f934fe0a7dc36f1f9008")
        let publicKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        testSubstrateNetwork(
            .polkadot(testnet: false),
            publicKey: publicKey,
            expectedAddress: "12twBQPiG5yVSf3jQSBkTAKBKqCShQ5fm33KQhH3Hf6VDoKW"
        )
        
        testSubstrateNetwork(
            .polkadot(testnet: false),
            publicKey: edKey,
            expectedAddress: "14cermZiQ83ihmHKkAucgBT2sqiRVvd4rwqBGqrMnowAKYRp"
        )
    }
    
    func testKusama() throws {
        // From trust wallet `KusamaTests.swift`
        let privateKey = Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
        let publicKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
        try testSubstrateNetwork(
            .kusama,
            publicKey: publicKey,
            expectedAddress: "HewiDTQv92L2bVtkziZC8ASxrFUxr6ajQ62RXAnwQ8FDVmg"
        )
        
        try testSubstrateNetwork(
            .kusama,
            publicKey: edKey,
            expectedAddress: "GByNkeXAhoB1t6FZEffRyytAp11cHt7EpwSWD8xiX88tLdQ"
        )
    }
    
    func testWestend() {
        testSubstrateNetwork(
            .polkadot(testnet: true),
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }
    
    func testAzero() {
        testSubstrateNetwork(
            .azero(testnet: true),
            publicKey: edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }
    
    func testSubstrateNetwork(_ blockchain: Blockchain, publicKey: Data, expectedAddress: String) {
        let network = PolkadotNetwork(blockchain: blockchain)!
        let service = PolkadotAddressService(network: network)
        
        let address = try! service.makeAddress(from: publicKey)
        let addressFromString = PolkadotAddress(string: expectedAddress, network: network)

        XCTAssertThrowsError(try service.makeAddress(from: secpCompressedKey))
        XCTAssertThrowsError(try service.makeAddress(from: secpDecompressedKey))

        XCTAssertNotNil(addressFromString)
        XCTAssertEqual(addressFromString!.bytes(raw: true), publicKey)
        XCTAssertEqual(address.value, expectedAddress)
        XCTAssertNotEqual(addressFromString!.bytes(raw: false), publicKey)
    }
    
    func testTron() throws {
        // From https://developers.tron.network/docs/account
        let blockchain = Blockchain.tron(testnet: false)
        let service = TronAddressService()

        let publicKey = Data(hexString: "0404B604296010A55D40000B798EE8454ECCC1F8900E70B1ADF47C9887625D8BAE3866351A6FA0B5370623268410D33D345F63344121455849C9C28F9389ED9731")
        let address = try service.makeAddress(from: publicKey)
        XCTAssertEqual(address.value, "TDpBe64DqirkKWj6HWuR1pWgmnhw2wDacE")
        
        let compressedKeyAddress = try service.makeAddress(from: secpCompressedKey)
        XCTAssertEqual(compressedKeyAddress.value, "TL51KaL2EPoAnPLgnzdZndaTLEbd1P5UzV")
        
        let decompressedKeyAddress = try service.makeAddress(from: secpDecompressedKey)
        XCTAssertEqual(decompressedKeyAddress.value, "TL51KaL2EPoAnPLgnzdZndaTLEbd1P5UzV")
        
        XCTAssertTrue(service.validate("TJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"))
        XCTAssertFalse(service.validate("RJRyWwFs9wTFGZg3JbrVriFbNfCug5tDeC"))
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: publicKey, for: blockchain), address.value)
    }
    
    // MARK: - Dash addresses

    func testDashCompressedMainnet() throws {
        // given
        let blockchain = Blockchain.dash(testnet: false)
        let service = BitcoinLegacyAddressService(networkParams: DashMainNetworkParams())
        let expectedAddress = "XtRN6njDCKp3C2VkeyhN1duSRXMkHPGLgH"
        
        // when
        let address = try service.makeAddress(from: secpCompressedKey)

        // then
        XCTAssertEqual(address.value, expectedAddress)
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: secpCompressedKey, for: blockchain), address.value)
    }
    
    func testDashDecompressedMainnet() throws {
        // given
        let service = BitcoinLegacyAddressService(networkParams: DashMainNetworkParams())
        let expectedAddress = "Xs92pJsKUXRpbwzxDjBjApiwMK6JysNntG"

        // when
        let address = try service.makeAddress(from: secpDecompressedKey)

        // then
        XCTAssertEqual(address.value, expectedAddress)
    }
    
    func testDashTestnet() throws {
        // given
        let service = BitcoinLegacyAddressService(networkParams: DashTestNetworkParams())
        let expectedAddress = "yMfdoASh4QEM3zVpZqgXJ8St38X7VWnzp7"
        let compressedKey = Data(
            hexString: "021DCF0C1E183089515DF8C86DACE6DA08DC8E1232EA694388E49C3C66EB79A418"
        )
        
        // when
        let address = try service.makeAddress(from: compressedKey)

        // then
        XCTAssertEqual(address.value, expectedAddress)
    }
    
    func testTON() {
        let blockchain = Blockchain.ton(testnet: false)
        let addressService = WalletCoreAddressService(coin: .ton)
        
        let walletPubkey1 = Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb")
        let expectedAddress1 = "EQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrYeu"
        XCTAssertEqual(try addressService.makeAddress(from: walletPubkey1).value, expectedAddress1)
        
        let walletPubkey2 = Data(hex: "258A89B60CCE7EB3339BF4DB8A8DA8153AA2B6489D22CC594E50FDF626DA7AF5")
        let expectedAddress2 = "EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"
        XCTAssertEqual(try addressService.makeAddress(from: walletPubkey2).value, expectedAddress2)
        
        let walletPubkey3 = Data(hex: "f42c77f931bea20ec5d0150731276bbb2e2860947661245b2319ef8133ee8d41")
        let expectedAddress3 = "EQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts90Q"
        XCTAssertEqual(try addressService.makeAddress(from: walletPubkey3).value, expectedAddress3)
        
        let walletPubkey4 = Data(hexString: "0404B604296010A55D40000B798EE8454ECCC1F8900E70B1ADF47C9887625D8BAE3866351A6FA0B5370623268410D33D345F63344121455849C9C28F9389ED9731")
        XCTAssertNil(try? addressService.makeAddress(from: walletPubkey4))
        
        let walletPubkey5 = Data(hexString: "042A5741873B88C383A7CFF4AA23792754B5D20248F1A24DF1DAC35641B3F97D8936D318D49FE06E3437E31568B338B340F4E6DF5184E1EC5840F2B7F4596902AE")
        XCTAssertNil(try? addressService.makeAddress(from: walletPubkey5))
        
        XCTAssertNil(try? addressService.makeAddress(from: secpCompressedKey))
        XCTAssertNil(try? addressService.makeAddress(from: secpDecompressedKey))
        
        try XCTAssertEqual(addressesUtility.makeTrustWalletAddress(publicKey: walletPubkey1, for: blockchain), expectedAddress1)
    }
    
    func testTONValidateCorrectAddress() {
        let addressService = WalletCoreAddressService(coin: .ton)
        
        XCTAssertTrue(addressService.validate("EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"))
        XCTAssertTrue(addressService.validate("EQAGDzFFIxJswaBU5Rqaz5H5dKUBGYEMhL44fpLtIdWbjkBo"))
        XCTAssertTrue(addressService.validate("EQA0i8-CdGnF_DhUHHf92R1ONH6sIA9vLZ_WLcCIhfBBXwtG"))
        XCTAssertTrue(addressService.validate("0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"))
        XCTAssertTrue(addressService.validate("0:66fbe3c5c03bf5c82792f904c9f8bf28894a6aa3d213d41c20569b654aadedb3"))
        XCTAssertFalse(addressService.validate("8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"))
    }
    
    func testKaspaAddressGeneration() throws {
        let addressService = KaspaAddressService()
        
        let expectedAddress = "kaspa:qypyrhxkfd055qulcvu6zccq4qe63qajrzgf7t4u4uusveguw6zzc3grrceeuex"
        XCTAssertEqual(try addressService.makeAddress(from: secpCompressedKey).value, expectedAddress)
        XCTAssertEqual(try addressService.makeAddress(from: secpDecompressedKey).value, expectedAddress)
        
        // https://github.com/kaspanet/kaspad/pull/2202/files
        // https://github.com/kaspanet/kaspad/blob/dev/util/address_test.go
        let kaspaTestPublicKey = Data([
            0x02, 0xf1, 0xd3, 0x78, 0x05, 0x46, 0xda, 0x20, 0x72, 0x8e, 0xa8, 0xa1, 0xf5, 0xe5, 0xe5, 0x1b, 0x84, 0x38, 0x00, 0x2c, 0xd7, 0xc8, 0x38, 0x2a, 0xaf, 0xa7, 0xdd, 0xf6, 0x80, 0xe1, 0x25, 0x57, 0xe4,
        ])
        let kaspaTestAddress = "kaspa:qyp0r5mcq4rd5grj3652ra09u5dcgwqq9ntuswp247nama5quyj40eq03sc2dkx"
        XCTAssertEqual(try addressService.makeAddress(from: kaspaTestPublicKey).value, kaspaTestAddress)
        
        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
    }
    
    func testKaspaAddressComponentsAndValidation() throws {
        let addressService = KaspaAddressService()
        
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
    
    func testRavencoinAddress() throws {
         let addressService = BitcoinLegacyAddressService(networkParams: RavencoinMainNetworkParams())
        
        let compAddress = try addressService.makeAddress(from: secpCompressedKey)
        let expectedCompAddress = "RT1iM3xbqSQ276GNGGNGFdYrMTEeq4hXRH"
        XCTAssertEqual(compAddress.value, expectedCompAddress)
        
        let decompAddress = try addressService.makeAddress(from: secpDecompressedKey)
        let expectedDecompAddress = "RRjP4a6i7e1oX1mZq1rdQpNMHEyDdSQVNi"
        XCTAssertEqual(decompAddress.value, expectedDecompAddress)
        
        XCTAssertTrue(addressService.validate(compAddress.value))
        XCTAssertTrue(addressService.validate(decompAddress.value))
     }
    
    func testCosmosAddress() throws {
        let addressService = WalletCoreAddressService(coin: .cosmos)
        
        let expectedAddress = "cosmos1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5emztyek"
        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpCompressedKey).value)
        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpDecompressedKey).value)
        
        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
        
        let validAddresses = [
            "cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02",
            "cosmospub1addwnpepqftjsmkr7d7nx4tmhw4qqze8w39vjq364xt8etn45xqarlu3l2wu2n7pgrq",
            "cosmosvaloper1sxx9mszve0gaedz5ld7qdkjkfv8z992ax69k08",
            "cosmosvalconspub1zcjduepqjnnwe2jsywv0kfc97pz04zkm7tc9k2437cde2my3y5js9t7cw9mstfg3sa",
        ]
        
        for validAddress in validAddresses {
            XCTAssertTrue(addressService.validate(validAddress))
        }
        
        let invalidAddresses = [
            "cosmoz1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02",
            "osmo1mky69cn8ektwy0845vec9upsdphktxt0en97f5",
            "cosmosvaloper1sxx9mszve0gaedz5ld7qdkjkfv8z992ax69k03",
            "cosmosvalconspub1zcjduepqjnnwe2jsywv0kfc97pz04zkm7tc9k2437cde2my3y5js9t7cw9mstfg3sb",
        ]
        for invalidAddress in invalidAddresses {
            XCTAssertFalse(addressService.validate(invalidAddress))
        }
    }
    
    func testTerraAddress() throws {
        let blockchains: [Blockchain] = [
            .terraV1,
            .terraV2,
        ]
        
        for blockchain in blockchains {
            try testTerraAddress(blockchain: blockchain)
        }
    }
    
    func testTerraAddress(blockchain: Blockchain) throws {
        let addressService = WalletCoreAddressService(blockchain: blockchain)
        let expectedAddress = "terra1c2zwqqucrqvvtyxfn78ajm8w2sgyjf5eax3ymk"
        
        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpCompressedKey).value)
        XCTAssertEqual(expectedAddress, try addressService.makeAddress(from: secpDecompressedKey).value)
        
        XCTAssertThrowsError(try addressService.makeAddress(from: edKey))
        
        XCTAssertTrue(addressService.validate("terra1hdp298kaz0eezpgl6scsykxljrje3667d233ms"))
        XCTAssertTrue(addressService.validate("terravaloper1pdx498r0hrc2fj36sjhs8vuhrz9hd2cw0yhqtk"))
        XCTAssertFalse(addressService.validate("cosmos1hsk6jryyqjfhp5dhc55tc9jtckygx0eph6dd02"))
    }
    
    func testChiaAddressService() throws {
        let blockchain = Blockchain.chia(testnet: true)
        let addressService = ChiaAddressService(isTestnet: true)
//
//        addressService.validate("txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f6jvdgkmf5gtq8g3aw3")
        try! addressService.make()
    }
}
