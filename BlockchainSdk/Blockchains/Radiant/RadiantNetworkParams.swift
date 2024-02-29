//
//  RadiantNetworkParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 28.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

/*
    name: 'livenet',
    alias: 'mainnet',
    prefix: 'bitcoin',
    cashAddrPrefix: 'bitcoincash',
    pubkeyhash: 0x00,
    privatekey: 0x80,
    scripthash: 0x05,
    xpubkey: 0x0488b21e,
    xprivkey: 0x0488ade4,
    networkMagic: networkMagic.livenet,
    port: 8333,
    dnsSeeds: dnsSeeds
 
    name: 'testnet',
    prefix: TESTNET.PREFIX,
    cashAddrPrefix: TESTNET.CASHADDRPREFIX,
    pubkeyhash: 0x6f,
    privatekey: 0xef,
    scripthash: 0xc4,
    xpubkey: 0x043587cf,
    xprivkey: 0x04358394,
    networkMagic: TESTNET.NETWORK_MAGIC
 */

class RadiantNetworkParams: INetwork {
    let bundleName = "livenet"

    let pubKeyHash: UInt8 = 0x00 //addressHeader
    let privateKey: UInt8 = 0x80 //dumpedPrivateKeyHeader
    let scriptHash: UInt8 = 0x05 //p2shHeader
    let bech32PrefixPattern: String = "bitcoincash" //segwitAddressHrp
    let xPubKey: UInt32 = 0x0488b21e //bip32HeaderP2PKHpub
    let xPrivKey: UInt32 = 0x0488ade4 //bip32HeaderP2PKHpriv
    let magic: UInt32 = RadiantNetworkMagic.livenet //packetMagic
    let port: UInt32 = 8333 //port
    let coinType: UInt32 = 145
    let sigHash: SigHashType = .bitcoinCashAll
    var syncableFromApi: Bool = true

    let dnsSeeds: [String] = RadiantNetworkConstants.dnsSeeds

    let dustRelayTxFee = 3000 //  https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
}

class RadiantTestNetworkParams: INetwork {
    let bundleName = "testnet"
    
    let pubKeyHash: UInt8 = 0x6f
    let privateKey: UInt8 = 0xef
    let scriptHash: UInt8 = 0xc4
    let bech32PrefixPattern: String = "bchtest"
    let xPubKey: UInt32 = 0x043587cf
    let xPrivKey: UInt32 = 0x04358394
    let magic: UInt32 = RadiantNetworkMagic.testnet
    let port: UInt32 = 18333
    let coinType: UInt32 = 1
    let sigHash: SigHashType = .bitcoinCashAll
    var syncableFromApi: Bool = true
    
    let dnsSeeds: [String] = RadiantNetworkConstants.dnsSeeds
    
    let dustRelayTxFee = 1000    // https://github.com/Bitcoin-ABC/bitcoin-abc/blob/master/src/policy/policy.h#L78
}

enum RadiantNetworkMagic {
    static let livenet: UInt32 = 0xe3e1f3e8
    static let testnet: UInt32 = 0xf4e5f3f4
    static let regtest: UInt32 = 0xdab5bffa
    static let stn: UInt32 = 0xfbcec4f9
}

enum RadiantNetworkConstants {
    static let dnsSeeds = [
      "seed.bitcoinsv.org",
      "seed.bitcoinunlimited.info",
    ]
}
