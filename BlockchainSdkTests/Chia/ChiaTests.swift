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
        let walletPublicKey = Data(hexString: "8FAC07255C7F3FE670E21E49CC5E70328F4181440A535CC18CF369FD280BA18FA26E28B52035717DB29BFF67105894B2")
        let sendValue = Decimal("0.0003")!
        let feeValue = Decimal("0.000000164238")!
        let destinationAddress = "xch1g36l3auawuejw3nvq08p29lw4wst4qrq9hddvtn9vv9nz822avgsrwte2v"
        let sourceAddress = try! addressService.makeAddress(from: walletPublicKey)
        
        let transactionBuilder = ChiaTransactionBuilder(
            isTestnet: blockchain.isTestnet,
            walletPublicKey: walletPublicKey
        )
        
        let unspentCoins = [
             ChiaCoin(
                amount: 5199843583,
                parentCoinInfo: "0x34ddaf3f1500f45b2afe2d8783f8abbde57f82be02bf2f6661095c6b20cd12cb",
                puzzleHash: "0x9488ae2f6f0d2655aca94c6e658fdc31bd2217f74d676407112c0558d3d217d2"
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
        
        let expectedHashToSign1 = Data(hexString: "8242AB52301FF9B0DDBD5C3219729720794D96C4BDE074BEC3FB4FEFBAC5AA37831B02578BF5C3AAAF37835F9B83C29709B3DF84D9A33CCB6700CCC2B3FFF9777603CD4F12A3EE3F26C2F425B6998BA9F586E5ADF5BCBBD1935995607C9E0DC0")
        
        let expectedSignedTransaction = ChiaSpendBundle(
            aggregatedSignature: "a1af85f8f921d18c1e6a81481d3e9cbf89caad7632a825dbbdeefa4c7a918903436f0b37cad1156dfd90ae94d2c0270d08e07190543dcd4e0e2a94ae2f15960ed3adb40e7ac1166bd5bfbfcc536389cfe0e1967db9ff00d09df1a1e3210460ee",
            coinSpends: [
                ChiaCoinSpend(
                    coin: unspentCoins[0],
                    puzzleReveal: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b08fac07255c7f3fe670e21e49cc5e70328f4181440a535cc18cf369fd280ba18fa26e28b52035717db29bff67105894b2ff018080",
                    solution: "ffffff33ffa04475f8f79d773327466c03ce1517eeaba0ba80602ddad62e65630b311d4aeb11ff8411e1a30080ffff33ffa09488ae2f6f0d2655aca94c6e658fdc31bd2217f74d676407112c0558d3d217d2ff8501240b2c71808080"
                )
            ]
        )
        
        let signature1 = Data(hexString: "A1AF85F8F921D18C1E6A81481D3E9CBF89CAAD7632A825DBBDEEFA4C7A918903436F0B37CAD1156DFD90AE94D2C0270D08E07190543DCD4E0E2A94AE2F15960ED3ADB40E7AC1166BD5BFBFCC536389CFE0E1967DB9FF00D09DF1A1E3210460EE")
        
        let buildToSignResult = try! transactionBuilder.buildForSign(transaction: transactionData)
        let signedTransaction = try! transactionBuilder.buildToSend(signatures: [signature1])
        
        XCTAssertTrue(buildToSignResult.contains([expectedHashToSign1]))
        try! XCTAssertEqual(jsonEncoder.encode(signedTransaction), jsonEncoder.encode(expectedSignedTransaction))
    }
    
    @available(iOS 16.0, *)
    func testTransactionVector2() {
        let walletPublicKey = Data(hexString: "8FAC07255C7F3FE670E21E49CC5E70328F4181440A535CC18CF369FD280BA18FA26E28B52035717DB29BFF67105894B2")
        
        let sendValue = Decimal("0.006")!
        let feeValue = Decimal("0.000000164238")!
        let destinationAddress = "xch1g36l3auawuejw3nvq08p29lw4wst4qrq9hddvtn9vv9nz822avgsrwte2v"
        let sourceAddress = try! addressService.makeAddress(from: walletPublicKey)
        
        let transactionBuilder = ChiaTransactionBuilder(
            isTestnet: blockchain.isTestnet,
            walletPublicKey: walletPublicKey
        )
        
        let unspentCoins = [
             ChiaCoin(
                amount: 6000000000,
                parentCoinInfo: "0x352edeba78e03024c377790db1ad7b0ade3ecc412b17c4d3a149138d1f5229ee",
                puzzleHash: "0x9488ae2f6f0d2655aca94c6e658fdc31bd2217f74d676407112c0558d3d217d2"
             ),
             ChiaCoin(
                amount: 4899679345,
                parentCoinInfo: "0xfc62fff2391312518bcf08feabc842ca2c21ff1e0de2f97f36bae58194b1fb98",
                puzzleHash: "0x9488ae2f6f0d2655aca94c6e658fdc31bd2217f74d676407112c0558d3d217d2"
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
        
        let hashToSignes = [
            Data(hexString: "AD7DD23E9E3D1F758CAE501DB0BE3B46C9C0DEF54EB0420A8398D7E200C3CECA64B689608AF33E4CAEE72D8A5560B2AA15E64256AE6FE0300F913A9DCB5C99A7CD5FAFA144C3AA9BE5F9965F84F92AF5880F91A4BB81A8795DA622E90B15E97B"),
            Data(hexString: "8AF2B9F9905F119B63D33E11CCD98B0D41F4EF13A32F109CCC8A31DEA7FCED00FC6C976E66B0F4E97065DE0BAE61986F16FBEE581C5CFC860EFEA49506A1CFAF05FB2F9C47ED47C128C6EE89872FD67856A64ACFE88244BBB6B9E6A7729F494A"),
        ]
        
        let expectedSignedTransaction = ChiaSpendBundle(
            aggregatedSignature: "b6e6ec29d4475e1ac063eb1c915fa8e4277d5ca184fe9cbe9c1b43e70ddb36f0c9cf35aa17c18adcf7feb1e966cce3b41910ef036e37ac8b7aabdf88811bbf479e9e847cbfed1fa22c198c1d4928303f2136bdddb266137abd3d39a98130669b",
            coinSpends: [
                ChiaCoinSpend(
                    coin: unspentCoins[0],
                    puzzleReveal: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b08fac07255c7f3fe670e21e49cc5e70328f4181440a535cc18cf369fd280ba18fa26e28b52035717db29bff67105894b2ff018080",
                    solution: "ffffff33ffa04475f8f79d773327466c03ce1517eeaba0ba80602ddad62e65630b311d4aeb11ff850165a0bc0080ffff33ffa09488ae2f6f0d2655aca94c6e658fdc31bd2217f74d676407112c0558d3d217d2ff85012403f7f8808080"
                ),
                ChiaCoinSpend(
                    coin: unspentCoins[1],
                    puzzleReveal: "ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b08fac07255c7f3fe670e21e49cc5e70328f4181440a535cc18cf369fd280ba18fa26e28b52035717db29bff67105894b2ff018080",
                    solution: "ffffff01808080"
                ),
            ]
        )
        
        let signatures = [
            Data(hexString: "A85B6F48DE90005DAC80C5ACD6883631B5B192F5ED6CAF4C811EEBF8E1C533840913E7DE497544AE70E2F80CB306EA5D04EF9889FC179E8C71591E3A0E4035C9E1A4504C1E7CC22E59872787D2E6C620B2F90D2512D041709F47DB9A35F95F75"),
            Data(hexString: "8171CC308912AEEB71F0A5FCA36E1098775349D9D5B09D65371C1A0150B71575836542900CE91540A133B0A8F955BF60144DD33C0BED093E4C08DB9C4141D3C7DC6E466BC90B31F72366C919F036B35CA411E2CB709D29398A5DD614788050A0"),
        ]
        
        let buildToSignResult = try! transactionBuilder.buildForSign(transaction: transactionData)
        let signedTransaction = try! transactionBuilder.buildToSend(signatures: signatures)
        
        try! print(jsonEncoder.encode(signedTransaction).hex)
        try! print(jsonEncoder.encode(expectedSignedTransaction).hex)
        
        
        XCTAssertTrue(buildToSignResult.contains(hashToSignes))
//        try! XCTAssertEqual(jsonEncoder.encode(signedTransaction).hexString, jsonEncoder.encode(expectedSignedTransaction).hexString)
    }
    
    func testSizeTransaction() throws {
        let signature1 = Data(hexString: "8C7470BEE98156B48A0909F6EF321DE86F073101399ACD160ACFEF57B943B6E76E22DC89D9C75ABBFAC97DC317FEA3CC0AD744F55E2EAA3AE3C099AFC89FE652B8B054C5AB1F6A11559A9BCFD132EE0F434BA4D7968A33EA1807CFAB097789B7")
        let signature2 = Data(hexString: "93CFBA81239EAD3358E780073DCC9553097F377B217A8FE04CB07D4FC634F2A094425D8A9E8E2373880AD944EDB55ECF16D59F031986E9EFEB92290C3E7285227890E7FC3EAFFC84B84F225E62CFA5ED681DCE6993C9845543AA493180B28B04")
        
        sizeUtility.testTxSizes([signature1, signature2])
    }
    
}
