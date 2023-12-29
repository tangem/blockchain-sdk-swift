//
//  VeChainTests.swift
//  BlockchainSdkTests
//
//  Created by Andrey Fedorov on 28.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import WalletCore

@testable import BlockchainSdk

final class VeChainTests: XCTestCase {
    private let blockchain: BlockchainSdk.Blockchain = .veChain(testnet: true)

    private let token = Token(
        name: "VeThor",
        symbol: "VTHO",
        contractAddress: "0x0000000000000000000000000000456e65726779",
        decimalCount: 18
    )

    private var addressService: AddressService!
    private var transactionBuilder: VeChainTransactionBuilder!
    private var sizeTester: TransactionSizeTesterUtility!

    override func setUp() {
        addressService = AddressServiceFactory(blockchain: blockchain).makeAddressService()
        transactionBuilder = .init(blockchain: blockchain)
        sizeTester = .init()
    }

    override func tearDown() {
        addressService = nil
        transactionBuilder = nil
        sizeTester = nil
    }

    // VeChain VET coin transfer transaction:
    // https://explore-testnet.vechain.org/transactions/0x4c596f671d3b48a8a973494699875feb9d4ed8304bfde5ec1547620a4320d9dc
    // Made using VeChain Thor Devkit (SDK) for Python 3, https://github.com/vechain/thor-devkit.py
    func testSigningCoinTransaction() throws {
        // Private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury" mnemonic
        let privateKeyRaw = Data(hexString: "0x11573efc409f42822eb39ca248d5e39edcf3377f0d4049b633d4dac3a54d5e71")
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))

        let publicKeyRaw = privateKey.getPublicKeySecp256k1(compressed: false).data
        let publicKey = Wallet.PublicKey(seedKey: publicKeyRaw, derivationType: nil)

        let sourceAddress = try addressService.makeAddress(for: publicKey, with: .default).value
        let expectedSourceAddress = "0xce270ba263dbB31FEb49Ec769A2C50FeCE7a6130"

        XCTAssertEqual(sourceAddress, expectedSourceAddress)

        let destinationAddress = "0x207F32eB8d9E6f5178336f86c2ebc3E1A4f87211"
        let value = try XCTUnwrap(Decimal(string: "1.2"))
        let amount = Amount(with: blockchain, value: value)

        let feeValue: Amount = .zeroCoin(for: blockchain)   // Doesn't affect fee calculation
        let feeParams = VeChainFeeParams(priority: .medium)
        let fee = Fee(feeValue, parameters: feeParams)

        let blockInfo = VeChainBlockInfo(
            blockId: "0x0109263b18b36f3c5cf3f2282fd634153ed37d76ac1ec737cc40b2bae4fbb0be",
            blockRef: 0x0109263b18b36f3c,
            blockNumber: 17_376_827
        )

        let transactionParams = VeChainTransactionParams(
            publicKey: publicKey,
            lastBlockInfo: blockInfo,
            nonce: 849_203_818
        )

        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress,
            params: transactionParams
        )

        let transactionHash = try transactionBuilder.buildForSign(transaction: transaction)

        sizeTester.testTxSize(transactionHash)

        let curve = try Curve(blockchain: blockchain)
        let transactionSignature = try XCTUnwrap(privateKey.sign(digest: transactionHash, curve: curve))

        let signedTransaction = try transactionBuilder.buildForSend(
            transaction: transaction,
            hash: transactionHash,
            signature: transactionSignature
        )

        let encodedTransaction = signedTransaction.hexString

        let expectedEncodedTransaction = """
F87B27880109263B18B36F3C81B4E0DF94207F32EB8D9E6F5178336F86C2EBC3E1A4F872118810A741A462780000807F825\
2088084329DD26AC0B841D4A16F16647224B53C396F9A1C41C95696B6CCDFD211BA409FE107AB3653E8B179772CBA8D0F12\
787D1F39AA0C608F2E0DBA157F2BB1071BF03E62BAB6DDF11801
"""

        XCTAssertEqual(encodedTransaction, expectedEncodedTransaction)
    }

    // VeChain VTHO token transfer transaction:
    // https://explore-testnet.vechain.org/transactions/0x5cf9d03b97460768b9d86718fbec03f09ed0e41467b7df4eaa68f1115abd4cf9
    // Made using VeChain Thor Devkit (SDK) for Python 3, https://github.com/vechain/thor-devkit.py
    func testSigningTokenTransaction() throws {
        // Private key for the "tiny escape drive pupil flavor endless love walk gadget match filter luxury" mnemonic
        let privateKeyRaw = Data(hexString: "0x11573efc409f42822eb39ca248d5e39edcf3377f0d4049b633d4dac3a54d5e71")
        let privateKey = try XCTUnwrap(WalletCore.PrivateKey(data: privateKeyRaw))

        let publicKeyRaw = privateKey.getPublicKeySecp256k1(compressed: false).data
        let publicKey = Wallet.PublicKey(seedKey: publicKeyRaw, derivationType: nil)

        let sourceAddress = try addressService.makeAddress(for: publicKey, with: .default).value
        let expectedSourceAddress = "0xce270ba263dbB31FEb49Ec769A2C50FeCE7a6130"

        XCTAssertEqual(sourceAddress, expectedSourceAddress)

        let destinationAddress = "0xecDA0279640ad26749061eB467155943d1BEd821"
        let value = try XCTUnwrap(Decimal(string: "2.45"))
        let amount = Amount(with: blockchain, type: .token(value: token), value: value)

        let feeValue: Amount = .zeroCoin(for: blockchain)   // Doesn't affect fee calculation
        let feeParams = VeChainFeeParams(priority: .high)
        let fee = Fee(feeValue, parameters: feeParams)

        let blockInfo = VeChainBlockInfo(
            blockId: "0x01092bdf0faf64b0faf92130d6eb41ff237390ad73035fac75d6ce32f29aa5ca",
            blockRef: 0x01092bdf0faf64b0,
            blockNumber: 17_378_271
        )

        let transactionParams = VeChainTransactionParams(
            publicKey: publicKey,
            lastBlockInfo: blockInfo,
            nonce: 109_290_847
        )

        let transaction = Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: sourceAddress,
            destinationAddress: destinationAddress,
            changeAddress: sourceAddress,
            params: transactionParams
        )

        let transactionHash = try transactionBuilder.buildForSign(transaction: transaction)

        sizeTester.testTxSize(transactionHash)

        let curve = try Curve(blockchain: blockchain)
        let transactionSignature = try XCTUnwrap(privateKey.sign(digest: transactionHash, curve: curve))

        let signedTransaction = try transactionBuilder.buildForSend(
            transaction: transaction,
            hash: transactionHash,
            signature: transactionSignature
        )

        let encodedTransaction = signedTransaction.hexString

        let expectedEncodedTransaction = """
F8BB278801092BDF0FAF64B081B4F85EF85C940000000000000000000000000000456E6572677980B844A9059CBB0000000\
00000000000000000ECDA0279640AD26749061EB467155943D1BED821000000000000000000000000000000000000000000\
00000022002604F3B5000081FF82CF8880840683A55FC0B841C2F4CF465B5BA4E0966CB0D31B40F08445ED8AFD6A5D869F0\
0E420AB4B4472D40D25F33A0BB3CDE09A8405EE7B0741BC7FB3C1C93C905EEAC78D3AD7E7C566F601
"""

        XCTAssertEqual(encodedTransaction, expectedEncodedTransaction)
    }

    func testFeeCalculation() throws {
        // TODO: Andrey Fedorov - Add actual implementation
    }
}
