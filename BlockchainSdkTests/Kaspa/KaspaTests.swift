//
//  KaspaTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Chukavin on 16.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import BitcoinCore
import TangemSdk

@testable import BlockchainSdk

class KaspaTests: XCTestCase {
    private let blockchain = Blockchain.kaspa
//    private let networkParams =  LitecoinNetworkParams()
    private let sizeTester = TransactionSizeTesterUtility()
    
    func testBuildTransaction() {
        let txBuilder = KaspaTransactionBuilder(blockchain: blockchain)
        
        txBuilder.unspentOutputs = [
            BlockchainSdk.BitcoinUnspentOutput(transactionHash: "deb88e7dd734437c6232a636085ef917d1d13cc549fe14749765508b2782f2fb", outputIndex: 0, amount: 10000000, outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"),
            BlockchainSdk.BitcoinUnspentOutput(transactionHash: "304db39069dc409acedf544443dcd4a4f02bfad4aeb67116f8bf087822c456af", outputIndex: 0, amount: 10000000, outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"),
            BlockchainSdk.BitcoinUnspentOutput(transactionHash: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a", outputIndex: 0, amount: 500000000, outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"),
        ]
        
        let walletPublicKey = "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F"
        let sourceAddress = try! blockchain.getAddressService().makeAddress(from: Data(hex: walletPublicKey))
        let destination = "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv"
        
        let transaction = Transaction(amount: Amount(with: blockchain, value: 0.001), fee: Amount(with: blockchain, value: 0.0003), sourceAddress: sourceAddress, destinationAddress: destination, changeAddress: sourceAddress)
        
        let hashes = txBuilder.buildForSign(transaction)
        
        let expectedHashes = [
            Data(hex: "0FF3D00405C24E8FCC4B6E0FF619D8C6CEDCA595672B5510F835A834B0841878"),
            Data(hex: "A414377AB154AB4A2BAB714F0398F230B8DAD7B7267B67AF40FAC47FB90B5124"),
            Data(hex: "040D5D2E734A47117377D64FCF2B621612E336E99F122E54302A569D37F8B483"),
        ]
        XCTAssertEqual(hashes, expectedHashes)        
    }
}
