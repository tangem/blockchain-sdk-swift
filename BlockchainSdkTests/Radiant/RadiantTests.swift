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
//        let legacyOutputScript = buildOutputScript(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf")!.hexString
        
//        XCTAssertEqual(lockScript.data.hexString.lowercased(), "76a9140a2f12f228cbc244c745f33a23f7e924cbf3b6ad88ac".lowercased())
//        XCTAssertEqual(lockScript.data.hexString.lowercased(), legacyOutputScript.lowercased())
    }
    
    func testHDKey() throws {
        let hdWallet = WalletCore.HDWallet(
            mnemonic: "tiny escape drive pupil flavor endless love walk gadget match filter luxury",
            passphrase: ""
        )
        
        let privateKey = hdWallet!.getKeyForCoin(coin: .bitcoinCash)
        
        print(privateKey.data.hexString)
        
        let hexPublicKey = privateKey.getPublicKeySecp256k1(compressed: true).data.hexString
        
        print(hexPublicKey)
        
        let publicKey = Wallet.PublicKey(seedKey: Data(hexString: hexPublicKey), derivationType: .none)
        
        let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
        let adapterAddress = try addressAdapter.makeAddress(for: publicKey, by: .p2pkh)
        
        print(adapterAddress.description)
        
//        let publicKey = Data(hexString: "02AB010392F0C638AC572C61AA72D37460D4B4AA722DFA258863ADE24998C72CFA")
//        let p2pkhScript = WalletCore.BitcoinScript.buildPayToPublicKeyHash(hash: publicKey)
//        let lockScript = BitcoinScript.lockScriptForAddress(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf", coin: .bitcoinCash)
//        let legacyOutputScript = buildOutputScript(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf")!.hexString
//        
//        XCTAssertEqual(lockScript.data.hexString.lowercased(), "76a9140a2f12f228cbc244c745f33a23f7e924cbf3b6ad88ac".lowercased())
//        XCTAssertEqual(lockScript.data.hexString.lowercased(), legacyOutputScript.lowercased())
    }
    
    func testUtils() throws {
        let scripthash = try RadiantUtils().prepareWallet(address: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf")
        XCTAssertEqual("972C432D04BC6908FA2825860148B8F911AC3D19C161C68E7A6B9BEAE86E05BA", scripthash)
        
        let scripthash1 = try RadiantUtils().prepareWallet(address: "166w5AGDyvMkJqfDAtLbTJeoQh6FqYCfLQ")
        XCTAssertEqual("67809980FB38F7685D46A8108A39FE38956ADE259BE1C3E6FECBDEAA20FDECA9", scripthash1)
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
    
    func testSignPreImage() throws {
        let privateKey = WalletCore.PrivateKey(data: Data(hexString: "079E750E71A7A2680380A4744C0E84567B1F8FC3C0AFD362D8326E1E676A4A15"))!
        let publicKey = privateKey.getPublicKeySecp256k1(compressed: true)
        let decimalValue = blockchain.decimalValue
        
        let addressAdapter = BitcoinWalletCoreAddressAdapter(coin: .bitcoinCash)
        let adapterAddress = try addressAdapter.makeAddress(
            for: Wallet.PublicKey(seedKey: publicKey.data, derivationType: .none),
            by: .p2pkh
        )
        
        XCTAssertEqual("166w5AGDyvMkJqfDAtLbTJeoQh6FqYCfLQ", adapterAddress.description)
        
        let outputScript = WalletCore.BitcoinScript.lockScriptForAddress(address: adapterAddress.description, coin: WalletCore.CoinType.bitcoinCash).data.hexString
        
        XCTAssertEqual(outputScript.lowercased(), "76a91437f7d8745fb391f80384c4c375e6e884ee4cec2888ac")
        
        let txBuilder = try RadiantCashTransactionBuilder(walletPublicKey: publicKey.data, decimalValue: decimalValue)
        
        let unspent = BitcoinUnspentOutput(
            transactionHash: "9f7a9794c66d223acf580ac88fd1e932e6b6f98fe2e86670b6cd31190123963d",
            outputIndex: 0,
            amount: 278337500,
            outputScript: outputScript
        )
        
        txBuilder.update(unspents: [unspent])
        
        let amountValue = Amount(with: blockchain, value: 1.39168750)
        let feeValue = Amount(with: blockchain, value: 0.00226)
        
        let hashesForSign = try txBuilder.buildForSign(
            transaction: .init(
                amount: amountValue,
                fee: Fee(feeValue),
                sourceAddress: adapterAddress.description,
                destinationAddress: "1vr9gJkNzTHv8DEQb4QBxAnQCxgzkFkbf",
                changeAddress: "166w5AGDyvMkJqfDAtLbTJeoQh6FqYCfLQ"
            )
        )
        
        XCTAssertEqual(hashesForSign.first?.hexString.lowercased(), "64c71563e9e2b34934b464f741e9d99787aa5a4741059475dc10a5f336ed117d")
        
        let signature = privateKey.signAsDER(digest: hashesForSign.first!)
        print(signature?.hexadecimal)
        
        /*
         3045022100e3669ab54e95a6c085587b34c32ae5454cb6fff1a34a7570105787488490184f02202c2de2bb1c6a06cdc98f5c98b0d018f7f595db2a7c29ef00087ee53ac68079fb
         
         3044022025b8d6a4c77de4e4e3c525ea130ac0c76fa827468b3837aff95517cc685069c0022071bf4147aed3d15c0892ea59e32c2e89e41304e5a6c1138a1551df3b9c391296
         */
    }
}
