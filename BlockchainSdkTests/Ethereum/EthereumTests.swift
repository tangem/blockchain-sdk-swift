//
//  EthereumTests.swift
//  BlockchainSdkTests
//
//  Created by Andrew Son on 03/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import XCTest
import BigInt
import TangemSdk

@testable import BlockchainSdk

class EthereumTests: XCTestCase {
    private let addressService = WalletCoreAddressService(coin: .ethereum)
    private let blockchain = Blockchain.ethereum(testnet: false)
    private let gasLimit = BigUInt(21000)
    private let sizeTester = TransactionSizeTesterUtility()
    
    func testAddress() throws {
        let walletPubKey = Data(hex: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820")
        let expectedAddress = "0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B"
        let address = try addressService.makeAddress(from: walletPubKey).value

        XCTAssertEqual(address, expectedAddress)
    }
    
    func testValidateCorrectAddress() {
        XCTAssertTrue(addressService.validate("0xc63763572d45171e4c25ca0818b44e5dd7f5c15b"))
    }
    
    func testValidateCorrectAddressWithChecksum() {
        XCTAssertTrue(addressService.validate("0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B"))
    }

    func test() throws {
        let unmarshal2 = try Secp256k1Signature(
            with: Data(hex: "28ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa63627667cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d8300")
        )
            .unmarshal(
                with: Data(hex: "044bc2a31265153f07e70e0bab08724e6b85e217f8cd628ceb62974247bb493382ce28cab79ad7119ee1ad3ebcdb98a16805211530ecc6cfefa1b88e6dff99232a"),
                hash: Data(hex: "daf5a779ae972f972197303d7b574746c7ef83eadac0f2791ad23db92e4c8e53")
            )
        XCTAssertEqual(BigUInt(unmarshal2.v), BigUInt(27))
    }

    func test_legacy_coin_transfer() throws {
        // given
        let walletPublicKey = Data(hex: "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F")
        let signature = Data(hex: "B945398FB90158761F6D61789B594D042F0F490F9656FBFFAE8F18B49D5F30054F43EE43CCAB2703F0E2E4E61D99CF3D4A875CD759569787CF0AED02415434C6")
        let destinationAddress = "0x7655b9b19ffab8b897f836857dae22a1e7f8d735"
        let nonce = 15
        let walletAddress = "0xb1123efF798183B7Cb32F62607D3D39E950d9cc3"
        let sendAmount = Amount(with: blockchain, type: .coin, value: 0.1)
        let feeParameters = EthereumFeeParameters(gasLimit: BigUInt(21000), gasPrice: BigUInt(476190476190))

        // feeAmount doesn't matter. The EthereumFeeParameters used to build the transaction
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        let transaction = Transaction(
            amount: sendAmount,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress
        )

        // when
        let transactionBuilder = try EthereumTransactionBuilder(walletPublicKey: walletPublicKey, chainId: 1)
        transactionBuilder.update(nonce: nonce)
        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)

        // then
        let expectedHashToSign = Data(hex: "BDBECF64B443F82D1F9FDA3F2D6BA69AF6D82029B8271339B7E775613AE57761")
        let expectedSignedTransaction = Data(hex: "F86C0F856EDF2A079E825208947655B9B19FFAB8B897F836857DAE22A1E7F8D73588016345785D8A00008025A0B945398FB90158761F6D61789B594D042F0F490F9656FBFFAE8F18B49D5F3005A04F43EE43CCAB2703F0E2E4E61D99CF3D4A875CD759569787CF0AED02415434C6")
        
        sizeTester.testTxSize(hashToSign)
        XCTAssertEqual(hashToSign, expectedHashToSign)
        XCTAssertEqual(signedTransaction, expectedSignedTransaction)
    }
    
    func test_legacy_token_transfer() throws {
        // given
        let walletPublicKey = Data(hex: "04EB30400CE9D1DEED12B84D4161A1FA922EF4185A155EF3EC208078B3807B126FA22C335081AAEBF161095C11C7D8BD550EF8882A3125B0EE9AE96DDDE1AE743F")
        let signature = Data(hex: "F408C40F8D8B4A40E35502355C87FBBF218EC9ECB036D42DAA6211EAD4498A6FBC800E82CB2CC0FAB1D68FD3F8E895EC3E0DCB5A05342F5153210142E4224D4C")

        let walletAddress = "0xb1123efF798183B7Cb32F62607D3D39E950d9cc3"
        let contractAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        let destinationAddress = "0x7655b9b19ffab8b897f836857dae22a1e7f8d735"
        let token = Token(name: "USDC Coin", symbol: "USDC", contractAddress: contractAddress, decimalCount: 18)

        let nonce = 15
        let sendValue = Amount(with: blockchain, type: .token(value: token), value: 0.1)
        let feeParameters = EthereumFeeParameters(gasLimit: BigUInt(21000), gasPrice: BigUInt(476190476190))
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        // when
        let transactionBuilder = try EthereumTransactionBuilder(walletPublicKey: walletPublicKey, chainId: 1)
        transactionBuilder.update(nonce: nonce)
        let transaction = Transaction(
            amount: sendValue,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress
        )

        // then
        let expectedHashToSign = Data(hex: "2F47B058A0C4A91EC6E26372FA926ACB899235D7A639565B4FC82C7A9356D6C5")
        let expectedSignedTransaction = Data(hex: "F8A90F856EDF2A079E82520894A0B86991C6218B36C1D19D4A2E9EB0CE3606EB4880B844A9059CBB0000000000000000000000007655B9B19FFAB8B897F836857DAE22A1E7F8D735000000000000000000000000000000000000000000000000016345785D8A000025A0F408C40F8D8B4A40E35502355C87FBBF218EC9ECB036D42DAA6211EAD4498A6FA0437FF17D34D33F054E29702C07176A127CA1118CAA1470EA6CB15D49EC13F3F5")

        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        XCTAssertEqual(hashToSign, expectedHashToSign)

        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        XCTAssertEqual(signedTransaction.hexString, expectedSignedTransaction.hexString)
    }

    // https://polygonscan.com/tx/0x8f7c7ffddfc9f45370cc5fbeb49df65bdf8976ba606d20705eea965ba96a1e8d
    func test_eip1559_token_transfer() throws {
        // given
        let walletPublicKey = Data(hex: "043b08e56e38404199eb3320f32fdc7557029d4a4c39adae01cc47afd86cfa9a25fcbfaa2acda3ab33560a1d482a2088f3bb2c7b313fd11f50dd8fe508165d4ecf")
        let signature = Data(hex: "b8291b199416b39434f3c3b8cfd273afb41fa25f2ae66f8a4c56b08ad1749a122148b8bbbdeb7761031799ffbcbc7c0ee1dd4482f516bd6a33387ea5bce8cb7d")

        let walletAddress = "0x29010F8F91B980858EB298A0843264cfF21Fd9c9"
        let contractAddress = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
        let destinationAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        let token = Token(name: "Tether", symbol: "USDT", contractAddress: contractAddress, decimalCount: 6)

        let nonce = 195
        let sendValue = Amount(with: blockchain, type: .token(value: token), value: 1)
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(47525),
            baseFee: BigUInt(138077377799),
            priorityFee: BigUInt(30000000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        // when
        let transactionBuilder = try EthereumTransactionBuilder(walletPublicKey: walletPublicKey, chainId: 137)
        transactionBuilder.update(nonce: nonce)
        let transaction = Transaction(
            amount: sendValue,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress
        )

        // then
        let expectedHashToSign = Data(hex: "7843727fd03b42156222548815759dda5ac888033372157edffdde58fc05eff5")
        let expectedSignedTransaction = Data(hex: "0x02f8b3818981c38506fc23ac008520260d950782b9a594c2132d05d31c914a87c6611c10748aeb04b58e8f80b844a9059cbb00000000000000000000000090e4d59c8583e37426b37d1d7394b6008a987c6700000000000000000000000000000000000000000000000000000000000f4240c080a0b8291b199416b39434f3c3b8cfd273afb41fa25f2ae66f8a4c56b08ad1749a12a02148b8bbbdeb7761031799ffbcbc7c0ee1dd4482f516bd6a33387ea5bce8cb7d")

        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        XCTAssertEqual(hashToSign, expectedHashToSign)

        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        XCTAssertEqual(signedTransaction.hexString, expectedSignedTransaction.hexString)
    }

    // https://polygonscan.com/tx/0x9a6ac4bea9ef483d15d32cdb4b51b86854583e1e55bbbaf7ed66bdf636673cf2
    func test_eip1559_coin_transfer() throws {
        // given
        let walletPublicKey = Data(hex: "043b08e56e38404199eb3320f32fdc7557029d4a4c39adae01cc47afd86cfa9a25fcbfaa2acda3ab33560a1d482a2088f3bb2c7b313fd11f50dd8fe508165d4ecf")
        let signature = Data(hex: "DA17C0AEBF8BCCC45501BE97EDC73CCCA69A13AC65DE667A4A288C3F24E6DCE77C37E31BF5380746F9A633DA0EB079A56AC7A2D024A80C2F537415F68947EC50")

        let walletAddress = "0x29010F8F91B980858EB298A0843264cfF21Fd9c9"
        let destinationAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"

        let nonce = 195
        let sendValue = Amount(with: blockchain, type: .coin, value: 1)
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(21000),
            baseFee: BigUInt(221985475379),
            priorityFee: BigUInt(30000000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        // when
        let transactionBuilder = try EthereumTransactionBuilder(walletPublicKey: walletPublicKey, chainId: 137)
        transactionBuilder.update(nonce: nonce)
        let transaction = Transaction(
            amount: sendValue,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress
        )

        // then
        let expectedHashToSign = Data(hex: "0f7bb229fc3605e5df8f3c29fc3f5cae7c016d5e3505137b7590a59587177307")
        let expectedSignedTransaction = Data(hex: "0x02f876818981c38506fc23ac008533af5d8b338252089490e4d59c8583e37426b37d1d7394b6008a987c67880de0b6b3a764000080c080a0da17c0aebf8bccc45501be97edc73ccca69a13ac65de667a4a288c3f24e6dce7a07c37e31bf5380746f9a633da0eb079a56ac7a2d024a80c2f537415f68947ec50")

        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        XCTAssertEqual(hashToSign, expectedHashToSign)

        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        XCTAssertEqual(signedTransaction.hexString, expectedSignedTransaction.hexString)
    }

    func testParseBalance() {
        let hex = "0x373c91e25f1040"
        let hex2 = "0x00000000000000000000000000000000000000000000000000373c91e25f1040"
        XCTAssertEqual(EthereumUtils.parseEthereumDecimal(hex, decimalsCount: 18)!.description, "0.015547720984891456")
        XCTAssertEqual(EthereumUtils.parseEthereumDecimal(hex2, decimalsCount: 18)!.description, "0.015547720984891456")
        
        // vBUSD contract sends extra zeros
        let vBUSDHexWithExtraZeros = "0x0000000000000000000000000000000000000000000000000000005a8c504ec900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        let vBUSDHexWithoutExtraZeros = "0x0000000000000000000000000000000000000000000000000000005a8c504ec9"
        XCTAssertEqual(EthereumUtils.parseEthereumDecimal(vBUSDHexWithExtraZeros,    decimalsCount: 18)!.description, "0.000000388901129929")
        XCTAssertEqual(EthereumUtils.parseEthereumDecimal(vBUSDHexWithoutExtraZeros, decimalsCount: 18)!.description, "0.000000388901129929")
        
        // This is rubbish and we don't expect to receive this but at least it should not throw exceptions
        let tooBig = "0x01234567890abcdef01234567890abcdef01234501234567890abcdef01234567890abcdef01234501234567890abcdef012345def01234501234567890abcdef012345def01234501234567890abcdef012345def01234501234567890abcdef01234567890abcdef012345"
        XCTAssertNil(EthereumUtils.parseEthereumDecimal(tooBig, decimalsCount: 18))
    }
}
