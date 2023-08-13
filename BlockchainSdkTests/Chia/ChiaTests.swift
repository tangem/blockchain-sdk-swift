//
//  ChiaTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 10.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import CryptoKit
import TangemSdk

@testable import BlockchainSdk

class ChiaTests: XCTestCase {
    private let sizeUtility = TransactionSizeTesterUtility()
    private let jsonEncoder = JSONEncoder()
    
    private let blockchain = Blockchain.chia(testnet: false)
    private let addressService = ChiaAddressService(isTestnet: false)
    private var decimals: Int { blockchain.decimalCount }
    
    private let walletPublicKey = Data(hexString: "A259D941E9C70ADB0DFA5B7DDC399D7EDA3FE263B24CFD8123114B6C89A2E8C5263D063F48DABF50D72C05A2AFC0F4FC")
    
    func testConditionSpend() {
        let address = "txch14gxuvfmw2xdxqnws5agt3ma483wktd2lrzwvpj3f6jvdgkmf5gtq8g3aw3"
        let amount: Int64 = 235834596465
        let encodedAmount = amount.chiaEncoded

        let solution1 = try! "ffffff33ffa0" +
        ChiaPuzzleUtils().getPuzzleHash(from: address).hex + "ff8" + String(encodedAmount.count) + encodedAmount.hex + "808080"
        
        let condition = try! CreateCoinCondition(
            destinationPuzzleHash: ChiaPuzzleUtils().getPuzzleHash(from: address),
            amount: amount
        ).toProgram()
        
        let solution2 = try! ClvmProgram.from(list: [ClvmProgram.from(list: [condition])]).serialize().hex
        
        XCTAssertEqual(solution1.lowercased(), solution2.lowercased())
    }
    
    @available(iOS 16.0, *)
    func testTransactionVector1() {
        let sendValue = Decimal("0.00001")!
        let feeValue = Decimal("0.000000087099")!
        let destinationAddress = "xch1jjy2utm0p5n9tt9ff3hxtr7uxx7jy9lhf4nkgpc39sz4357jzlfqrn6g0s"
        let sourceAddress = try! addressService.makeAddress(from: walletPublicKey)
        
        let transactionBuilder = ChiaTransactionBuilder(
            blockchain: blockchain,
            walletPublicKey: walletPublicKey
        )
        
        let unspentCoins = [
             ChiaCoin(
                amount: 108941365490,
                parentCoinInfo: "0x5f668219d248bb9a879e7b511d9efc640f006d021a697f88e15f20de1dd0e092",
                puzzleHash: "0x4475f8f79d773327466c03ce1517eeaba0ba80602ddad62e65630b311d4aeb11"
             )
        ]
        
        transactionBuilder.unspentCoins = unspentCoins
        
        let amountToSend = Amount(with: blockchain, value: sendValue)
        let fee = Fee(Amount(with: amountToSend, value: feeValue))
        
        let transactionData = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: sourceAddress.value,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress.value
        )
        
        let expectedHashToSign1 = Data(hexString: "814D6BDCF1DDE6ADFAD8A33F984576FC3AFDDAE6EB908E97D24428BAD106005246C14763CB678553356E5108DEB0C14D0FA14A11483AC4C28635690A1B64739924572E15160742833443F263D2845AEF6E8541C90AB00FCE4F234F206F5DEB05")
        
        let expectedSignedTransaction = ChiaSpendBundle(
            aggregatedSignature: "b3bf217ec0521ea9aac8d7ade52797997919cb6dcb768d1c7894da38b6238746cb917f3dfe13ae7a1a67ba6f1495375c0ba0380214282f6ae7a446fe7968a46bbe32c91940b01dbc1bd702099c7da787ef2151a3a7ec9c7831f499933886c70d",
            coinSpends: [
                ChiaCoinSpend(
                    coin: unspentCoins[0],
                    puzzleReveal: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0a259d941e9c70adb0dfa5b7ddc399d7eda3fe263b24cfd8123114b6c89a2e8c5263d063f48dabf50d72c05a2afc0f4fcff018080",
                    solution: "ffffff33ffa09488ae2f6f0d2655aca94c6e658fdc31bd2217f74d676407112c0558d3d217d2ff8080ffff33ffa04475f8f79d773327466c03ce1517eeaba0ba80602ddad62e65630b311d4aeb11ff85195ccf6637808080"
                )
            ]
        )
        
        let signature1 = Data(hexString: "B3BF217EC0521EA9AAC8D7ADE52797997919CB6DCB768D1C7894DA38B6238746CB917F3DFE13AE7A1A67BA6F1495375C0BA0380214282F6AE7A446FE7968A46BBE32C91940B01DBC1BD702099C7DA787EF2151A3A7EC9C7831F499933886C70D")
        
        let buildToSignResult = try! transactionBuilder.buildForSign(transaction: transactionData)
        let signedTransaction = try! transactionBuilder.buildToSend(signatures: [signature1])
        
        XCTAssertTrue(buildToSignResult.contains([expectedHashToSign1]))
        try! XCTAssertEqual(jsonEncoder.encode(signedTransaction), jsonEncoder.encode(expectedSignedTransaction))
    }
    
    @available(iOS 16.0, *)
    func testTransactionVector2() {
        let signature1 = Data(hexString: "8C7470BEE98156B48A0909F6EF321DE86F073101399ACD160ACFEF57B943B6E76E22DC89D9C75ABBFAC97DC317FEA3CC0AD744F55E2EAA3AE3C099AFC89FE652B8B054C5AB1F6A11559A9BCFD132EE0F434BA4D7968A33EA1807CFAB097789B7")
        let signature2 = Data(hexString: "93CFBA81239EAD3358E780073DCC9553097F377B217A8FE04CB07D4FC634F2A094425D8A9E8E2373880AD944EDB55ECF16D59F031986E9EFEB92290C3E7285227890E7FC3EAFFC84B84F225E62CFA5ED681DCE6993C9845543AA493180B28B04")
        
        let sendValue = Decimal("0.1")!
        let feeValue = Decimal("0.000000164238")!
        let destinationAddress = "xch1wd52fhrnp2jjyxsqecfvkzq6geu3kxg9trq7m49ff0aadyxlclns7es9ph"
        let sourceAddress = try! addressService.makeAddress(from: walletPublicKey)
        
        let transactionBuilder = ChiaTransactionBuilder(
            blockchain: blockchain,
            walletPublicKey: walletPublicKey
        )
        
        let unspentCoins = [
             ChiaCoin(
                amount: 99790386,
                parentCoinInfo: "0x380ae38b677990a085ad7a9501da51a548f4241dbe73f78e969f019585e268a4",
                puzzleHash: "0x5d467bdc46c20f175024977ef0c2ae985abf9aea5151acbd6c54071de87a402b"
             ),
             ChiaCoin(
                amount: 114599994000,
                parentCoinInfo: "114599994000",
                puzzleHash: "0x5d467bdc46c20f175024977ef0c2ae985abf9aea5151acbd6c54071de87a402b"
             )
        ]
        
        transactionBuilder.unspentCoins = unspentCoins
        
        let amountToSend = Amount(with: blockchain, value: sendValue)
        let fee = Fee(Amount(with: amountToSend, value: feeValue))
        
        let transactionData = Transaction(
            amount: amountToSend,
            fee: fee,
            sourceAddress: sourceAddress.value,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress.value
        )
        
        let expectedHashToSign1 = Data(hexString: "A3A6136282A97B09CAE57DFAD492B78EAE685E2D55E3279D18B41CB11D2B0260EF6E5B2AE15E98956B0C4E652F86714203FFF9EFA7FED9D3ACF053FE697EE4D832B21484A711EB70989E2720FD262E8AD3E474909E7098DABD33870EF5DBC13A")
        
        let expectedHashToSign2 = Data(hexString: "8A4D295B39FF301BD565A98FC44E3F07D6B16421BC03FAF1B340AC7DF6230F979AA26CFA7086E9E3C4C09F2904FF5E8614AEA5F7F5883A2F7F20FF5F18C1BAAD0F895B2ABC8BBFF36254A5442CD6A6700A4E8ADFA1C9F7F8558EE23327592036")
        
        let expectedSignedTransaction = ChiaSpendBundle(
            aggregatedSignature: "93821E46F8A8FD5F38A63EF8B31D5DC0575B537DFE90CB2C03ADCF49C0AC3864BB5510B7908AC7D9B6DA41DFB09AEFC317C264697D40CA58C93A6EF8C66E0310B72389FFFCE69022FDC63E5B0CDD911FFDC4B45E56EE55ACBA936C4B26A8E71F",
            coinSpends: [
                ChiaCoinSpend(
                    coin: unspentCoins[0],
                    puzzleReveal: "FF02FFFF01FF02FFFF01FF04FFFF04FF04FFFF04FF05FFFF04FFFF02FF06FFFF04FF02FFFF04FF0BFF80808080FF80808080FF0B80FFFF04FFFF01FF32FF02FFFF03FFFF07FF0580FFFF01FF0BFFFF0102FFFF02FF06FFFF04FF02FFFF04FF09FF80808080FFFF02FF06FFFF04FF02FFFF04FF0DFF8080808080FFFF01FF0BFFFF0101FF058080FF0180FF018080FFFF04FFFF01B0B6B57E5E5BFDE70E404CE83732548DB6E5BD1740C96F878B699E896FD99269B0EF10BD1C6A64E65A87C9AD444BA6E3CCFF018080",
                    solution: "FFFFFF33FFA07368A4DC730AA5221A00CE12CB081A46791B190558C1EDD4A94BFBD690DFC7E7FF85174876E80080FFFF33FFA05D467BDC46C20F175024977EF0C2AE985ABF9AEA5151ACBD6C54071DE87A402BFF85036C2B4B35808080"
                ),
                ChiaCoinSpend(
                    coin: unspentCoins[0],
                    puzzleReveal: "FF02FFFF01FF02FFFF01FF04FFFF04FF04FFFF04FF05FFFF04FFFF02FF06FFFF04FF02FFFF04FF0BFF80808080FF80808080FF0B80FFFF04FFFF01FF32FF02FFFF03FFFF07FF0580FFFF01FF0BFFFF0102FFFF02FF06FFFF04FF02FFFF04FF09FF80808080FFFF02FF06FFFF04FF02FFFF04FF0DFF8080808080FFFF01FF0BFFFF0101FF058080FF0180FF018080FFFF04FFFF01B0B6B57E5E5BFDE70E404CE83732548DB6E5BD1740C96F878B699E896FD99269B0EF10BD1C6A64E65A87C9AD444BA6E3CCFF018080",
                    solution: "FFFFFF01808080"
                )
            ]
        )
        
        let buildToSignResult = try! transactionBuilder.buildForSign(transaction: transactionData)
        let signedTransaction = try! transactionBuilder.buildToSend(signatures: [signature1, signature2])

//        XCTAssertTrue(buildToSignResult.contains([expectedHashToSign1, expectedHashToSign2]))
//        try! XCTAssertEqual(jsonEncoder.encode(signedTransaction), jsonEncoder.encode(expectedSignedTransaction))
    }
    
    func testSizeTransaction() throws {
        let signature1 = Data(hexString: "8C7470BEE98156B48A0909F6EF321DE86F073101399ACD160ACFEF57B943B6E76E22DC89D9C75ABBFAC97DC317FEA3CC0AD744F55E2EAA3AE3C099AFC89FE652B8B054C5AB1F6A11559A9BCFD132EE0F434BA4D7968A33EA1807CFAB097789B7")
        let signature2 = Data(hexString: "93CFBA81239EAD3358E780073DCC9553097F377B217A8FE04CB07D4FC634F2A094425D8A9E8E2373880AD944EDB55ECF16D59F031986E9EFEB92290C3E7285227890E7FC3EAFFC84B84F225E62CFA5ED681DCE6993C9845543AA493180B28B04")
        
        sizeUtility.testTxSizes([signature1, signature2])
    }
    
}
