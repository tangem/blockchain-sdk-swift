//
//  RadiantTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 01.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import XCTest
import WalletCore

import BitcoinCore

@testable import BlockchainSdk

final class RadiantTests: XCTestCase {
    private let blockchain = Blockchain.radiant(testnet: false)
    
    // MARK: - Impementation
    
    func testScript() throws {
        let publicKey = Data(hexString: "02AB010392F0C638AC572C61AA72D37460D4B4AA722DFA258863ADE24998C72CFA")
        let p2pkhScript = WalletCore.BitcoinScript.buildPayToPublicKeyHash(hash: publicKey)
        let lockScript = BitcoinScript.lockScriptForAddress(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf", coin: .bitcoinCash)
        let legacyOutputScript = buildOutputScript(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf")!.hexString
        
        XCTAssertEqual(lockScript.data.hexString.lowercased(), "76a9140a2f12f228cbc244c745f33a23f7e924cbf3b6ad88ac".lowercased())
        XCTAssertEqual(lockScript.data.hexString.lowercased(), legacyOutputScript.lowercased())
    }
    
    /// https://github.com/trustwallet/wallet-core/blob/master/tests/chains/Bitcoin/BitcoinAddressTests.cpp
    func testP2PKH_PrefixAddress() throws {
        let publicKey = Wallet.PublicKey(seedKey: Data(hexString: "039d645d2ce630c2a9a6dbe0cbd0a8fcb7b70241cb8a48424f25593290af2494b9"), derivationType: .none)
        let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
        let adapterAddress = try addressAdapter.makeAddress(for: publicKey, by: .p2pkh)
        
        let legacyAddressService = BitcoinLegacyAddressService(networkParams: BitcoinCashNetworkParams())
        let legacyAddress = try legacyAddressService.makeAddress(from: publicKey.blockchainKey)

        XCTAssertEqual(adapterAddress.description, "12dNaXQtN5Asn2YFwT1cvciCrJa525fAe4")
        XCTAssertEqual(adapterAddress.description, legacyAddress.value)
    }
    
    func testP2SH_PrefixAddress() throws {
        let publicKey = Wallet.PublicKey(seedKey: Data(hexString: "039d645d2ce630c2a9a6dbe0cbd0a8fcb7b70241cb8a48424f25593290af2494b9"), derivationType: .none)
        let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
        let adapterAddress = try addressAdapter.makeAddress(for: publicKey, by: .p2sh)
        
        let legacyAddressService = BitcoinLegacyAddressService(networkParams: BitcoinCashNetworkParams())
        let legacyAddress = try legacyAddressService.makeP2ScriptAddress(for: publicKey.blockchainKey)

        XCTAssertEqual(adapterAddress.description, "33KPW4uKuyVFsCEh4YgDMF58zprnb817jZ")
        XCTAssertEqual(adapterAddress.description, legacyAddress)
    }
    
    func testSign() throws {
        let blockchain: BlockchainSdk.Blockchain = .radiant(testnet: false)
        
        let privateKey = PrivateKey(data: Data(hexString: "7fdafb9db5bc501f2096e7d13d331dc7a75d9594af3d251313ba8b6200f4e384"))!
        let address = CoinType.bitcoinCash.deriveAddress(privateKey: privateKey)
        
        let utxoTxId = "050d00e2e18ef13969606f1ceee290d3f49bd940684ce39898159352952b8ce2"
        
        let transactionBuilder = RadiantTransactionBuilder(
            coinType: .bitcoinCash,
            publicKey: privateKey.getPublicKeyByType(pubkeyType: .secp256k1).compressed.data,
            decimalValue: blockchain.decimalValue,
            walletAddress: address
        )
        
        transactionBuilder.update(unspents: [
            .init(
                transactionHash: utxoTxId,
                outputIndex: 2,
                amount: 5151,
                outputScript: WalletCore.BitcoinScript.lockScriptForAddress(address: address, coin: .bitcoinCash).data.hexString // Build lock script from address or public key hash
            )
        ])
        
        let amount = Amount(with: blockchain, value: 600 / blockchain.decimalValue)
        let fee = Fee(Amount(with: blockchain, value: 1000 / blockchain.decimalValue))
        
        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: address,
            destinationAddress: "1Bp9U1ogV3A14FMvKbRJms7ctyso4Z4Tcx",
            changeAddress: "1FQc5LdgGHMHEN9nwkjmz6tWkxhPpxBvBU"
        )
        
        // TODO: - Need insert signed transaction
    
    }
    
    private func buildOutputScript(address: String) -> Data? {
        let decoded = address.base58DecodedData
        let first = decoded[0]
        let data = decoded[1...20]
        //P2H
        if (first == 0 || first == 111 || first == 48) { //0 for BTC/BCH 1 address | 48 for LTC L address
            return [Op.dup.rawValue, Op.hash160.rawValue ] + buildPrefix(for: data) + data + [Op.equalVerify.rawValue, Op.checkSig.rawValue]
        }
        //P2SH
        if(first == 5 || first == 0xc4 || first == 50) { //5 for BTC/BCH/LTC 3 address | 50 for LTC M address
            return [Op.hash160.rawValue] + buildPrefix(for: data) + data + [Op.equal.rawValue]
        }
        return nil
    }
    
    private func buildPrefix(for data: Data) -> Data {
        switch data.count {
        case 0..<Int(Op.pushData1.rawValue):
            return data.count.byte
        case Int(Op.pushData1.rawValue)..<Int(0xff):
            return Data([Op.pushData1.rawValue]) + data.count.byte
        case Int(0xff)..<Int(0xffff):
            return Data([Op.pushData2.rawValue]) + data.count.bytes2LE
        default:
            return Data([Op.pushData4.rawValue]) + data.count.bytes4LE
        }
    }
}

enum Op: UInt8 {
    case hash160 = 0xA9
    case equal = 0x87
    case dup = 0x76
    case equalVerify = 0x88
    case checkSig = 0xAC
    case pushData1 = 0x4c
    case pushData2 = 0x4d
    case pushData4 = 0x4e
    case op0 = 0x00
    case op1 = 0x51
}
