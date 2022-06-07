//
//  DashNetworkParams.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BitcoinCore

/*
 {
     "id": "dash",
     "name": "Dash",
     "coinId": 5,
     "symbol": "DASH",
     "decimals": 8,
     "blockchain": "Bitcoin",
     "derivation": [
       {
         "path": "m/44'/5'/0'/0/0",
         "xpub": "xpub",
         "xprv": "xprv"
       }
     ],
     "curve": "secp256k1",
     "publicKeyType": "secp256k1",
     "p2pkhPrefix": 76,
     "p2shPrefix": 16,
     "publicKeyHasher": "sha256ripemd",
     "base58Hasher": "sha256d"
 }
 */

/*
 // Dash addresses start with 'X'
 base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,76);
 // Dash script addresses start with '7'
 base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,16);
 // Dash private keys start with '7' or 'X'
 base58Prefixes[SECRET_KEY] =     std::vector<unsigned char>(1,204);
 // Dash BIP32 pubkeys start with 'xpub' (Bitcoin defaults)
 base58Prefixes[EXT_PUBLIC_KEY] = {0x04, 0x88, 0xB2, 0x1E};
 // Dash BIP32 prvkeys start with 'xprv' (Bitcoin defaults)
 base58Prefixes[EXT_SECRET_KEY] = {0x04, 0x88, 0xAD, 0xE4};

 // Dash BIP44 coin type is '5'
 nExtCoinType = 5;
 */

class DashNetworkParams: INetwork {
    let pubKeyHash: UInt8 = 0x00 //addressHeader
    let privateKey: UInt8 = 0x80 //dumpedPrivateKeyHeader
    let scriptHash: UInt8 = 0x05 //p2shHeader
    let bech32PrefixPattern: String = "bc" //segwitAddressHrp
    let xPubKey: UInt32 = 0x0488b21e //bip32HeaderP2PKHpub
    let xPrivKey: UInt32 = 0x0488ade4 //bip32HeaderP2PKHpriv
    let magic: UInt32 = 0xf9beb4d9 //packetMagic
    let port: UInt32 = 9999 //port
    let coinType: UInt32 = 0
    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = true
    
    let dnsSeeds = [
        "dnsseed.dashdot.io",
        "dnsseed.dash.org"
    ]
    
    // https://github.com/dashpay/dash/blob/master/src/policy/policy.h#38
    let dustRelayTxFee = 3000
}

/*
 // Testnet Dash addresses start with 'y'
 base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,140);
 // Testnet Dash script addresses start with '8' or '9'
 base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,19);
 // Testnet private keys start with '9' or 'c' (Bitcoin defaults)
 base58Prefixes[SECRET_KEY] =     std::vector<unsigned char>(1,239);
 // Testnet Dash BIP32 pubkeys start with 'tpub' (Bitcoin defaults)
 base58Prefixes[EXT_PUBLIC_KEY] = {0x04, 0x35, 0x87, 0xCF};
 // Testnet Dash BIP32 prvkeys start with 'tprv' (Bitcoin defaults)
 base58Prefixes[EXT_SECRET_KEY] = {0x04, 0x35, 0x83, 0x94};
 
 // Testnet Dash BIP44 coin type is '1' (All coin's testnet default)
 nExtCoinType = 1;
 */

class DashTestNetworkParams: INetwork {
    let pubKeyHash: UInt8 = 0x00 //addressHeader
    let privateKey: UInt8 = 0x80 //dumpedPrivateKeyHeader
    let scriptHash: UInt8 = 0x05 //p2shHeader
    let bech32PrefixPattern: String = "bc" //segwitAddressHrp
    let xPubKey: UInt32 = 0x0488b21e //bip32HeaderP2PKHpub
    let xPrivKey: UInt32 = 0x0488ade4 //bip32HeaderP2PKHpriv
    let magic: UInt32 = 0xf9beb4d9 //packetMagic
    let port: UInt32 = 19999 //port
    let coinType: UInt32 = 0
    let sigHash: SigHashType = .bitcoinAll
    var syncableFromApi: Bool = true
    
    let dnsSeeds = [
        "test.dnsseed.masternode.io",
        "testnet-seed.darkcoin.qa",
        "testnet-seed.dashpay.io"
    ]
    
    // https://github.com/dashpay/dash/blob/master/src/policy/policy.h#38
    let dustRelayTxFee = 3000
}


class BitcointMainNet: INetwork {
   let pubKeyHash: UInt8 = 0x00
   let privateKey: UInt8 = 0x80
   let scriptHash: UInt8 = 0x05
   let bech32PrefixPattern: String = "bc"
   let xPubKey: UInt32 = 0x0488b21e
   let xPrivKey: UInt32 = 0x0488ade4
   let magic: UInt32 = 0xf9beb4d9
   let port: UInt32 = 8333
   let coinType: UInt32 = 0
   let sigHash: SigHashType = .bitcoinAll

   let dnsSeeds = [
       "seed.bitcoin.sipa.be",         // Pieter Wuille
       "dnsseed.bluematt.me",          // Matt Corallo
       "dnsseed.bitcoin.dashjr.org",   // Luke Dashjr
       "seed.bitcoinstats.com",        // Chris Decker
       "seed.bitnodes.io",             // Addy Yeow
       "seed.bitcoin.jonasschnelli.ch",// Jonas Schnelli
   ]

   let dustRelayTxFee = 3000 //  https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
}
