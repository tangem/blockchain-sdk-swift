//
//  EthereumTests.swift
//  BlockchainSdkTests
//
//  Created by Andrew Son on 03/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import XCTest
@testable import BlockchainSdk

class EthereumTests: XCTestCase {

    private let addressService = EthereumAddressService()
    private let blockchain = Blockchain.ethereum(testnet: false)
    private let gasLimit = EthereumWalletManager.GasLimit.default.value
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func testAddress() {
        let walletPubKey = Data(hex: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820")
        let expectedAddress = "0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B"
        
        XCTAssertEqual(try! addressService.makeAddress(from: walletPubKey), expectedAddress)
    }
    
    func testValidateCorrectAddress() {
        XCTAssertTrue(addressService.validate("0xc63763572d45171e4c25ca0818b44e5dd7f5c15b"))
    }
    
    func testValidateCorrectAddressWithChecksum() {
        XCTAssertTrue(addressService.validate("0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B"))
    }
    
    func testBuildCoorectCoinTransaction() {
        let walletPublicKey = Data(hex: "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F")
        let signature = Data(hex: "B945398FB90158761F6D61789B594D042F0F490F9656FBFFAE8F18B49D5F30054F43EE43CCAB2703F0E2E4E61D99CF3D4A875CD759569787CF0AED02415434C6")
        
        let sendValue = Decimal(0.1)
        let feeValue = Decimal(0.01)
        let destinationAddress = "0x7655b9b19ffab8b897f836857dae22a1e7f8d735"
        let nonce = 15
        
        let walletAddress = try! addressService.makeAddress(from: walletPublicKey)
        let transactionBuilder = try! EthereumTransactionBuilder(walletPublicKey: walletPublicKey, chainId: 1)
        
        let sendAmount = Amount(with: blockchain, type: .coin, value: sendValue)
        let fee = Amount(with: blockchain, type: .coin, value: feeValue)
        
        let transaction = Transaction(amount: sendAmount, fee: fee, sourceAddress: walletAddress, destinationAddress: destinationAddress, changeAddress: walletAddress)
        
        let expectedHashToSign = Data(hex: "BDBECF64B443F82D1F9FDA3F2D6BA69AF6D82029B8271339B7E775613AE57761")
        let expectedSignedTransaction = Data(hex: "F86C0F856EDF2A079E825208947655B9B19FFAB8B897F836857DAE22A1E7F8D73588016345785D8A00008025A0B945398FB90158761F6D61789B594D042F0F490F9656FBFFAE8F18B49D5F3005A04F43EE43CCAB2703F0E2E4E61D99CF3D4A875CD759569787CF0AED02415434C6")
        
        let transactionToSign = transactionBuilder.buildForSign(transaction: transaction, nonce: nonce, gasLimit: gasLimit)
        XCTAssertNotNil(transactionToSign)
        let signedTransaction = transactionBuilder.buildForSend(transaction: transactionToSign!.transaction, hash: transactionToSign!.hash, signature: signature)
        XCTAssertNotNil(signedTransaction)
        XCTAssertEqual(transactionToSign?.hash, expectedHashToSign)
        XCTAssertEqual(signedTransaction, expectedSignedTransaction)
    }
    
    func testBuildCorrectTokenTransaction() {
        let walletPublicKey = Data(hex: "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F")
        let signature = Data(hex: "F408C40F8D8B4A40E35502355C87FBBF218EC9ECB036D42DAA6211EAD4498A6FBC800E82CB2CC0FAB1D68FD3F8E895EC3E0DCB5A05342F5153210142E4224D4C")
        
        let sendValue = Decimal(0.1)
        let feeValue = Decimal(0.01)
        let destinationAddress = "0x7655b9b19ffab8b897f836857dae22a1e7f8d735"
        let nonce = 15
        let contractAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        let token = Token(name: "USDC Coin", symbol: "USDC", contractAddress: contractAddress, decimalCount: 6)
        
        let walletAddress = try! addressService.makeAddress(from: walletPublicKey)
        let transactionBuilder = try! EthereumTransactionBuilder(walletPublicKey: walletPublicKey, chainId: 1)
        
        let amountToSend = Amount(with: blockchain, type: .token(value: token), value: sendValue)
        let fee = Amount(with: blockchain, type: .coin, value: feeValue)
        let transaction = Transaction(amount: amountToSend, fee: fee, sourceAddress: walletAddress, destinationAddress: destinationAddress, changeAddress: walletAddress, contractAddress: contractAddress)
        
        let expectedHashToSign = Data(hex: "2F47B058A0C4A91EC6E26372FA926ACB899235D7A639565B4FC82C7A9356D6C5")
        let expectedSignedTransaction = Data(hex: "F8A90F856EDF2A079E82520894A0B86991C6218B36C1D19D4A2E9EB0CE3606EB4880B844A9059CBB0000000000000000000000007655B9B19FFAB8B897F836857DAE22A1E7F8D735000000000000000000000000000000000000000000000000016345785D8A000025A0F408C40F8D8B4A40E35502355C87FBBF218EC9ECB036D42DAA6211EAD4498A6FA0437FF17D34D33F054E29702C07176A127CA1118CAA1470EA6CB15D49EC13F3F5")
        
        let transactionToSign = transactionBuilder.buildForSign(transaction: transaction, nonce: nonce, gasLimit: gasLimit)
        XCTAssertNotNil(transactionToSign)
        let signedTransaction = transactionBuilder.buildForSend(transaction: transactionToSign!.transaction, hash: transactionToSign!.hash, signature: signature)
        
        XCTAssertEqual(expectedHashToSign, transactionToSign?.hash)
        XCTAssertEqual(expectedSignedTransaction, signedTransaction)
    }
    
    func testParseBalance() {
        let hex = "0x373c91e25f1040"
        XCTAssertEqual(EthereumUtils.parseEthereumDecimal(hex, decimalsCount: 18)!.description, "0.015547720984891456")
        
        let tooBig = "0x01234567890abcdef01234567890abcdef01234501234567890abcdef01234567890abcdef01234501234567890abcdef012345def01234501234567890abcdef012345def01234501234567890abcdef012345def01234501234567890abcdef01234567890abcdef012345"
        XCTAssertNil(EthereumUtils.parseEthereumDecimal(tooBig, decimalsCount: 18))
    }
}
