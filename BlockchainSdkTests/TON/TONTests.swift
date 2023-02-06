//
//  TONTests.swift
//  BlockchainSdkTests
//
//  Created by skibinalexander on 12.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import XCTest
import BigInt
@testable import BlockchainSdk

class TONTests: XCTestCase {
    
    private let addressService = TONAddressService()
    private let transactionBuilder = try! TONTransactionBuilder(
        publicKey: Data(hexString: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb"),
        blockchain: .ton(testnet: true)
    )
    
    private let secretKey: String = "d31fd866151d4ccfd803d90f63b576dee6f3e7729e7afc78c95e5dc160ae369fe7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb"
    
    func testAddress() {
        let walletPubkey1 = Data(hex: "e7287a82bdcd3a5c2d0ee2150ccbc80d6a00991411fb44cd4d13cef46618aadb")
        let expectedAddress1 = "EQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrYeu"
        XCTAssertEqual(try! addressService.makeAddress(from: walletPubkey1), expectedAddress1)
        
        let walletPubkey2 = Data(hex: "258A89B60CCE7EB3339BF4DB8A8DA8153AA2B6489D22CC594E50FDF626DA7AF5")
        let expectedAddress2 = "EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"
        XCTAssertEqual(try! addressService.makeAddress(from: walletPubkey2), expectedAddress2)
        
        let walletPubkey3 = Data(hex: "f42c77f931bea20ec5d0150731276bbb2e2860947661245b2319ef8133ee8d41")
        let expectedAddress3 = "EQBm--PFwDv1yCeS-QTJ-L8oiUpqo9IT1BwgVptlSq3ts90Q"
        XCTAssertEqual(try! addressService.makeAddress(from: walletPubkey3), expectedAddress3)
    }
    
    func testValidateCorrectAddress() {
        XCTAssertTrue(addressService.validate("EQAoDMgtvyuYaUj-iHjrb_yZiXaAQWSm4pG2K7rWTBj9eOC2"))
        XCTAssertTrue(addressService.validate("EQAGDzFFIxJswaBU5Rqaz5H5dKUBGYEMhL44fpLtIdWbjkBo"))
        XCTAssertTrue(addressService.validate("EQA0i8-CdGnF_DhUHHf92R1ONH6sIA9vLZ_WLcCIhfBBXwtG"))
        XCTAssertTrue(addressService.validate("0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"))
        XCTAssertTrue(addressService.validate("0:66fbe3c5c03bf5c82792f904c9f8bf28894a6aa3d213d41c20569b654aadedb3"))
        XCTAssertFalse(addressService.validate("8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"))
    }
    
    func testSignTransaction() {
        let transactionForSign = try? transactionBuilder.buildForSign(
            transaction: .init(
                amount: Amount(with: .ton(testnet: true), value: 0.05),
                fee: Amount(with: .ton(testnet: true), value: 0),
                sourceAddress: "EQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrYeu",
                destinationAddress: "EQAKpgPeA917-iiCvOs4GFpMTeCu6I9XCKjd8T-NTpBLjBzo",
                changeAddress: "EQBqoh0pqy6zIksGZFMLdqV5Q2R7rzlTO0Durz6OnUgKrYeu"
            )
        )
        
        let transactionForSend = try? transactionBuilder.buildForSend(
            signingMessage: transactionForSign ?? TONCell(),
            signature: Data(hexString: secretKey)
        )
        
        XCTAssertFalse(transactionForSign == nil)
        XCTAssertFalse(transactionForSend == nil)
        
        let boc = (try? Data(transactionForSend!.message.toBoc(false)))?.base64EncodedString() ?? ""
        
        XCTAssertEqual(
            boc,
            "te6cckECGAEAA9EAAuGIANVEOlNWXWZElgzIphbtSvKGyPdecqZ2gd1efR06kBVaG0x/YZhUdTM/YA9kPY7V23ubz53Keevx4yV5dwWCuNp/nKHqCvc06XC0O4hUMy8gNagCZFBH7RM1NE870Zhiq2ympoxf/////AAAAAAADgEXAgE0AhYBFP8A9KQT9LzyyAsDAgEgBBECAUgFCALm0AHQ0wMhcbCSXwTgItdJwSCSXwTgAtMfIYIQcGx1Z70ighBkc3RyvbCSXwXgA/pAMCD6RAHIygfL/8nQ7UTQgQFA1yH0BDBcgQEI9ApvoTGzkl8H4AXTP8glghBwbHVnupI4MOMNA4IQZHN0crqSXwbjDQYHAHgB+gD0BDD4J28iMFAKoSG+8uBQghBwbHVngx6xcIAYUATLBSbPFlj6Ahn0AMtpF8sfUmDLPyDJgED7AAYAilAEgQEI9Fkw7UTQgQFA1yDIAc8W9ADJ7VQBcrCOI4IQZHN0coMesXCAGFAFywVQA88WI/oCE8tqyx/LP8mAQPsAkl8D4gIBIAkQAgEgCg8CAVgLDAA9sp37UTQgQFA1yH0BDACyMoHy//J0AGBAQj0Cm+hMYAIBIA0OABmtznaiaEAga5Drhf/AABmvHfaiaEAQa5DrhY/AABG4yX7UTQ1wsfgAWb0kK29qJoQICga5D6AhhHDUCAhHpJN9KZEM5pA+n/mDeBKAG3gQFImHFZ8xhAT48oMI1xgg0x/TH9MfAvgju/Jk7UTQ0x/TH9P/9ATRUUO68qFRUbryogX5AVQQZPkQ8qP4ACSkyMsfUkDLH1Iwy/9SEPQAye1U+A8B0wchwACfbFGTINdKltMH1AL7AOgw4CHAAeMAIcAC4wABwAORMOMNA6TIyx8Syx/L/xITFBUAbtIH+gDU1CL5AAXIygcVy//J0Hd0gBjIywXLAiLPFlAF+gIUy2sSzMzJc/sAyEAUgQEI9FHypwIAcIEBCNcY+gDTP8hUIEeBAQj0UfKnghBub3RlcHSAGMjLBcsCUAbPFlAE+gIUy2oSyx/LP8lz+wACAGyBAQjXGPoA0z8wUiSBAQj0WfKnghBkc3RycHSAGMjLBcsCUAXPFlAD+gITy2rLHxLLP8lz+wAACvQAye1UAFEAAAAAKamjF+coeoK9zTpcLQ7iFQzLyA1qAJkUEftEzU0TzvRmGKrbQACrSADVRDpTVl1mRJYMyKYW7Uryhsj3XnKmdoHdXn0dOpAVWwACqYD3gPde/oogrzrOBhaTE3gruiPVwio3fE/jU6QS4xAL68IAAAAAAAAAAAAAAAAAAEBZiriU"
        )
    }
    
}
