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
        let addresses = [
            "kaspa:qyp4scvsxvkrjxyq98gd4xedhgrqtmf78l7wl8p8p4j0mjuvpwjg5cqhy97n472",
            "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv",
            "kaspa:qyp7kvzqpn5arhhdz2uy6stp58afyth5rpdp2hhnassgq79nspa3ymcmyrw53q3", // tx source
            "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv", // tx dest
        ]
        for address in addresses {
            let s = CashAddrBech32.decode(address) 
            //        s.
            if let s {
                print("Address:\n\(address)")
                print(s.prefix)
                let type = Data(s.data.first!)
                let hash = s.data.dropFirst()
                print(type.hex)
                print(hash.hex)
//                print(try! blockchain.getAddressService().makeAddress(from: hash))
                
                print("")
            }
        }
        
        let txBuilder = KaspaTransactionBuilder(blockchain: blockchain)
        
        txBuilder.setUnspentOutputs([
            BlockchainSdk.BitcoinUnspentOutput(transactionHash: "deb88e7dd734437c6232a636085ef917d1d13cc549fe14749765508b2782f2fb", outputIndex: 0, amount: 10000000, outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"),
            BlockchainSdk.BitcoinUnspentOutput(transactionHash: "304db39069dc409acedf544443dcd4a4f02bfad4aeb67116f8bf087822c456af", outputIndex: 0, amount: 10000000, outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"),
            BlockchainSdk.BitcoinUnspentOutput(transactionHash: "ae96e819429e9da538e84cb213f62fbc8ad32e932d7c7f1fb9bd2fedf8fd7b4a", outputIndex: 0, amount: 500000000, outputScript: "21034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670dab"),
        ])
        
        let walletPublicKey = "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F"
        let sourceAddress = try! blockchain.getAddressService().makeAddress(from: Data(hex: walletPublicKey))
        print(sourceAddress)
        let destination = "kaspa:qpsqw2aamda868dlgqczeczd28d5nc3rlrj3t87vu9q58l2tugpjs2psdm4fv"
        
        let transaction = Transaction(
            amount: Amount(with: blockchain, value: 0.001),
            fee: Amount(with: blockchain, value: 0.000300000000001), // otherwise the tests fail, can't convert to 0.0003 properly
            sourceAddress: sourceAddress,
            destinationAddress: destination,
            changeAddress: sourceAddress
        )
        
        let (kaspaTransaction, hashes) = try! txBuilder.buildForSign(transaction)
        
        let expectedHashes = [
            Data(hex: "0FF3D00405C24E8FCC4B6E0FF619D8C6CEDCA595672B5510F835A834B0841878"),
            Data(hex: "A414377AB154AB4A2BAB714F0398F230B8DAD7B7267B67AF40FAC47FB90B5124"),
            Data(hex: "040D5D2E734A47117377D64FCF2B621612E336E99F122E54302A569D37F8B483"),
        ]
        XCTAssertEqual(hashes, expectedHashes)
        
        
        let signatures = [
            Data(hexString: "ED59AEECB1AC0BAF31B6D84BB51C060DBBC3E0321EEEE6FADEBF073099629A9A7247306451FD78488B1AAE38391DA6CAA72B52D2E6D9359F9C682EFCBF388B07"),
            Data(hexString: "00325BF907137BB6ED0A84D78C12F9680DD57AE374F45D43CDC7068ABF56F5B93C08BC1F9CD1E91E7A496DA2ECD54597B11AE0DDA4F6672235853C0CEF6BF8B4"),
            Data(hexString: "F408C40F8D8B4A40E35502355C87FBBF218EC9ECB036D42DAA6211EAD4498A6FBC800E82CB2CC0FAB1D68FD3F8E895EC3E0DCB5A05342F5153210142E4224D4C"),
        ]

        let z = txBuilder.buildForSend(transaction: kaspaTransaction, signatures: signatures)
        print(z)
    }
}
