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
    private let blockchain = Blockchain.ethereum(testnet: false)
    private let sizeTester = TransactionSizeTesterUtility()

    func testAddress() throws {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()

        let walletPubKey = Data(hex: "04BAEC8CD3BA50FDFE1E8CF2B04B58E17041245341CD1F1C6B3A496B48956DB4C896A6848BCF8FCFC33B88341507DD25E5F4609386C68086C74CF472B86E5C3820")
        let expectedAddress = "0xc63763572D45171e4C25cA0818b44E5Dd7F5c15B"
        let address = try addressService.makeAddress(from: walletPubKey).value

        XCTAssertEqual(address, expectedAddress)
    }
    
    func testValidationAddress() {
        let addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        XCTAssertTrue(addressService.validate("0xc63763572d45171e4c25ca0818b44e5dd7f5c15b"))
    }

    // https://polygonscan.com/tx/0x8f7c7ffddfc9f45370cc5fbeb49df65bdf8976ba606d20705eea965ba96a1e8d
    func testEIP1559TokenTransfer() throws {
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
            maxFeePerGas: BigUInt(138077377799),
            priorityFee: BigUInt(30000000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        // when
        let transactionBuilder = EthereumTransactionBuilder(chainId: 137)
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

    // https://polygonscan.com/tx/0x2cb6831f4c1cb7b888707489cd60c42ff222b5b3230d74f25434d936c2ba7419
    func testEIP1559CoinTransfer() throws {
        // given
        let walletPublicKey = Data(hex: "043b08e56e38404199eb3320f32fdc7557029d4a4c39adae01cc47afd86cfa9a25fcbfaa2acda3ab33560a1d482a2088f3bb2c7b313fd11f50dd8fe508165d4ecf")
        let signature = Data(hex: "56DF71FF2A7FE93D2363056FE5FF32C51E5AC71733AF23A82F3974CB872537E95B60D6A0042CC34724DB84E949EEC8643761FE9027E9E7B1ED3DA23D8AB7C0A4")

        let walletAddress = "0x29010F8F91B980858EB298A0843264cfF21Fd9c9"
        let destinationAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"

        let nonce = 196
        let sendValue = Amount(with: blockchain, type: .coin, value: 1)
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(21000),
            maxFeePerGas: BigUInt(4478253867089),
            priorityFee: BigUInt(31900000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        // when
        let transactionBuilder = EthereumTransactionBuilder(chainId: 137)
        transactionBuilder.update(nonce: nonce)
        let transaction = Transaction(
            amount: sendValue,
            fee: fee,
            sourceAddress: walletAddress,
            destinationAddress: destinationAddress,
            changeAddress: walletAddress
        )

        // then
        let expectedHashToSign = Data(hex: "925f1debbb96941544aefe6a5532508e51f2b8ae1f3a911abfb24b83af610400")
        let expectedSignedTransaction = Data(hex: "0x02f877818981c485076d635f00860412acbb20518252089490e4d59c8583e37426b37d1d7394b6008a987c67880de0b6b3a764000080c080a056df71ff2a7fe93d2363056fe5ff32c51e5ac71733af23a82f3974cb872537e9a05b60d6a0042cc34724db84e949eec8643761fe9027e9e7b1ed3da23d8ab7c0a4")

        let hashToSign = try transactionBuilder.buildForSign(transaction: transaction)
        sizeTester.testTxSize(hashToSign)
        XCTAssertEqual(hashToSign, expectedHashToSign)

        let signatureInfo = SignatureInfo(signature: signature, publicKey: walletPublicKey, hash: hashToSign)
        let signedTransaction = try transactionBuilder.buildForSend(transaction: transaction, signatureInfo: signatureInfo)
        XCTAssertEqual(signedTransaction.hexString, expectedSignedTransaction.hexString)
    }

    func testBuildDummyTransactionForL1() throws {
        // given
        let destinationAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"

        let nonce = 196
        let sendValue = EthereumUtils.mapToBigUInt(1 * blockchain.decimalValue).serialize()
        let feeParameters = EthereumEIP1559FeeParameters(
            gasLimit: BigUInt(21000),
            maxFeePerGas: BigUInt(4478253867089),
            priorityFee: BigUInt(31900000000)
        )
        let fee = Fee(.zeroCoin(for: blockchain), parameters: feeParameters)

        let transactionBuilder = EthereumTransactionBuilder(chainId: 1)
        transactionBuilder.update(nonce: nonce)

        // when
        let l1Data = try transactionBuilder.buildDummyTransactionForL1(
            destination: destinationAddress,
            value: sendValue.hexString,
            data: nil,
            fee: fee
        )

        // then
        XCTAssertEqual(l1Data.hexString, "02F30181C485076D635F00860412ACBB20518252089490E4D59C8583E37426B37D1D7394B6008A987C67880DE0B6B3A764000080C0")
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

    func testBuildingApproveTransactionPayload() throws {
        let transactionBuilder = EthereumTransactionBuilder(chainId: 10)
        let amount = try XCTUnwrap(Decimal(stringValue: "1146241"))

        let payload = transactionBuilder.buildForApprove(
            spender: "0x111111125421cA6dc452d289314280a0f8842A65",
            amount: amount
        )

        // https://optimistic.etherscan.io/tx/0x97141f7a1b450739bcf097fe41ca76c83897c0cc618e43b08fa0267865451c2b
        XCTAssertEqual(
            payload.hexString.addHexPrefix().lowercased(),
            "0x095ea7b3000000000000000000000000111111125421ca6dc452d289314280a0f8842a650000000000000000000000000000000000000000000000000000000000117d81"
        )
    }

    func testBuildingTokenTransferTransactionPayload() throws {
        let transactionBuilder = EthereumTransactionBuilder(chainId: 10)
        let amount = try XCTUnwrap(Decimal(stringValue: "0.001"))

        let payload = try transactionBuilder.buildForTokenTransfer(
            destination: "0x75739A5bd4B781cF38c59B9492ef9639e46688Bf",
            amount: .init(
                with: .optimism(testnet: false),
                type: .token(
                    value: .init(
                        name: "USD Coin",
                        symbol: "USDC",
                        contractAddress: "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85",
                        decimalCount: 6
                    )
                ),
                value: amount
            )
        )

        // https://optimistic.etherscan.io/tx/0x89a6b62628d326902df50f543996e9403df9a5d2ae5be415f7cdaa1a98464fd4
        XCTAssertEqual(
            payload.hexString.addHexPrefix().lowercased(),
            "0xa9059cbb00000000000000000000000075739a5bd4b781cf38c59b9492ef9639e46688bf00000000000000000000000000000000000000000000000000000000000003e8"
        )
    }
}
